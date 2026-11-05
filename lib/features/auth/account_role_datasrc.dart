import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';

class AccountRoleProfile {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool active;
  final bool mustChangePassword;
  final String? administratorId;
  final String? condominiumId;
  final DateTime? createdAt;

  const AccountRoleProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.active = true,
    this.mustChangePassword = false,
    this.administratorId,
    this.condominiumId,
    this.createdAt,
  });

  bool get isAdmin => role.isAdmin;

  bool get isLinkedToCondominium =>
      condominiumId != null && condominiumId!.trim().isNotEmpty;

  factory AccountRoleProfile.fromMap(String uid, Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];
    DateTime? parsedCreatedAt;
    if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt != null) {
      try {
        parsedCreatedAt = (rawCreatedAt as dynamic).toDate() as DateTime?;
      } catch (_) {
        parsedCreatedAt = null;
      }
    }

    return AccountRoleProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromMap(map, fallback: UserRole.user),
      active: map['active'] as bool? ?? true,
      mustChangePassword: map['mustChangePassword'] as bool? ?? false,
      administratorId: map['administratorId'] as String?,
      condominiumId: map['condominiumId'] as String?,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email.trim().toLowerCase(),
      'role': role.value,
      'isAdmin': isAdmin,
      'active': active,
      'mustChangePassword': mustChangePassword,
      'administratorId': administratorId,
      'condominiumId': condominiumId,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  AccountRoleProfile copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    bool? active,
    bool? mustChangePassword,
    String? administratorId,
    bool clearScope = false,
    String? condominiumId,
    DateTime? createdAt,
  }) {
    return AccountRoleProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      active: active ?? this.active,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      administratorId: clearScope
          ? null
          : (administratorId ?? this.administratorId),
      condominiumId: clearScope ? null : (condominiumId ?? this.condominiumId),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AccountRoleFirestoreDataSource {
  static const String collectionName = 'account_roles';

  final FirebaseFirestore? _injectedFirestore;

  AccountRoleFirestoreDataSource({FirebaseFirestore? firestore})
    : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<AccountRoleProfile?> getAccountRole(String uid) async {
    if (uid.trim().isEmpty) return null;
    final doc = await _collection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AccountRoleProfile.fromMap(doc.id, doc.data()!);
  }

  Future<List<AccountRoleProfile>> getAllAccountRoles() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => AccountRoleProfile.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> saveAccountRole(
    AccountRoleProfile profile, {
    bool isNew = false,
  }) async {
    final payload = <String, dynamic>{
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
    };
    await _collection.doc(profile.uid).set(payload, SetOptions(merge: true));
  }

  Future<AccountRoleProfile> resolveOrBootstrapSessionProfile({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final existing = await getAccountRole(uid);
    if (existing != null) {
      return existing;
    }

    // Conta legada (sem registro em account_roles/{uid} ainda):
    // Verifica se pertence à subcoleção users de algum condomínio (ex.: zelador1).
    final matchedCondoProfile = await _findLegacyCondominiumUser(
      uid: uid,
      normalizedEmail: normalizedEmail,
    );

    if (matchedCondoProfile != null) {
      try {
        await saveAccountRole(matchedCondoProfile, isNew: true);
      } catch (_) {}
      return matchedCondoProfile;
    }

    // Não é usuário operacional de condomínio -> conta administrativa pré-existente no Firebase Auth.
    final fallbackName =
        (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : (normalizedEmail.contains('@')
              ? normalizedEmail.split('@').first
              : 'Administrador');

    final bootstrappedAdmin = AccountRoleProfile(
      uid: uid,
      name: fallbackName,
      email: normalizedEmail,
      role: UserRole.admin,
      active: true,
      mustChangePassword: false,
      createdAt: DateTime.now(),
    );

    try {
      await saveAccountRole(bootstrappedAdmin, isNew: true);
    } catch (_) {}

    return bootstrappedAdmin;
  }

  Future<AccountRoleProfile?> _findLegacyCondominiumUser({
    required String uid,
    required String normalizedEmail,
  }) async {
    final adminsSnapshot = await _firestore.collection('administrators').get();

    for (final adminDoc in adminsSnapshot.docs) {
      final condosSnapshot = await adminDoc.reference
          .collection('condominiums')
          .get();

      for (final condoDoc in condosSnapshot.docs) {
        final usersCol = condoDoc.reference.collection('users');

        // 1. Busca direta por UID do Firebase Auth (padrão saveUserWithId)
        final byIdDoc = await usersCol.doc(uid).get();
        if (byIdDoc.exists && byIdDoc.data() != null) {
          final userModel = UserModel.fromMap(byIdDoc.id, byIdDoc.data()!);
          await _backfillCondoUserRoleFieldsIfMissing(
            byIdDoc.reference,
            byIdDoc.data()!,
            userModel,
          );
          return AccountRoleProfile(
            uid: uid,
            name: userModel.name,
            email: userModel.email.isNotEmpty
                ? userModel.email
                : normalizedEmail,
            role: userModel.role,
            active: userModel.active,
            mustChangePassword: userModel.mustChangePassword,
            administratorId: adminDoc.id,
            condominiumId: condoDoc.id,
            createdAt: userModel.createdAt,
          );
        }

        // 2. Fallback por e-mail caso tenha sido salvo com ID automático
        if (normalizedEmail.isNotEmpty) {
          final byEmailQuery = await usersCol
              .where('email', isEqualTo: normalizedEmail)
              .limit(1)
              .get();
          if (byEmailQuery.docs.isNotEmpty) {
            final foundDoc = byEmailQuery.docs.first;
            final userModel = UserModel.fromMap(foundDoc.id, foundDoc.data());
            await _backfillCondoUserRoleFieldsIfMissing(
              foundDoc.reference,
              foundDoc.data(),
              userModel,
            );
            return AccountRoleProfile(
              uid: uid,
              name: userModel.name,
              email: userModel.email,
              role: userModel.role,
              active: userModel.active,
              mustChangePassword: userModel.mustChangePassword,
              administratorId: adminDoc.id,
              condominiumId: condoDoc.id,
              createdAt: userModel.createdAt,
            );
          }
        }
      }
    }

    return null;
  }

  Future<void> _backfillCondoUserRoleFieldsIfMissing(
    DocumentReference<Map<String, dynamic>> docRef,
    Map<String, dynamic> rawData,
    UserModel parsed,
  ) async {
    if (rawData.containsKey('role') && rawData.containsKey('isAdmin')) {
      return;
    }
    try {
      await docRef.set({
        'role': parsed.role.value,
        'isAdmin': parsed.isAdmin,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}

class AccountRoleRepository {
  final AccountRoleFirestoreDataSource _dataSource;

  AccountRoleRepository({AccountRoleFirestoreDataSource? dataSource})
    : _dataSource = dataSource ?? AccountRoleFirestoreDataSource();

  Future<AccountRoleProfile?> getAccountRole(String uid) {
    return _dataSource.getAccountRole(uid);
  }

  Future<List<AccountRoleProfile>> getAllAccountRoles() {
    return _dataSource.getAllAccountRoles();
  }

  Future<void> saveAccountRole(
    AccountRoleProfile profile, {
    bool isNew = false,
  }) {
    return _dataSource.saveAccountRole(profile, isNew: isNew);
  }

  Future<AccountRoleProfile> resolveOrBootstrapSessionProfile({
    required String uid,
    required String email,
    String? displayName,
  }) {
    return _dataSource.resolveOrBootstrapSessionProfile(
      uid: uid,
      email: email,
      displayName: displayName,
    );
  }
}

final accountRoleRepositoryProvider = Provider<AccountRoleRepository>((ref) {
  return AccountRoleRepository();
});
