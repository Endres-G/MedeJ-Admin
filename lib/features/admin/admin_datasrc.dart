import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';

class AdministratorFirestoreDataSource {
  final FirebaseFirestore _firestore;

  AdministratorFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('administrators');

  Future<List<AdministratorModel>> getAdministrators({bool includeDeleted = false}) async {
    final snapshot = await _collection.get();

    final list = snapshot.docs
        .map((doc) => AdministratorModel.fromMap(doc.id, doc.data()))
        .toList();

    if (!includeDeleted) {
      return list.where((a) => !a.isDeleted).toList();
    }
    return list;
  }

  Future<List<AdministratorModel>> getDeletedAdministrators() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => AdministratorModel.fromMap(doc.id, doc.data()))
        .where((a) => a.isDeleted)
        .toList();
  }

  Future<AdministratorModel> getAdministrator(String id) async {
    final doc = await _collection.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('Administradora não encontrada.');
    }

    return AdministratorModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> createAdministrator(AdministratorModel administrator) async {
    final docRef = await _collection.add({
      ...administrator.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> updateAdministrator(AdministratorModel administrator) async {
    await _collection.doc(administrator.id).update(administrator.toMap());
  }

  /// Move a administradora para a lixeira (Soft Delete)
  Future<void> moveToTrash(String id) async {
    await _collection.doc(id).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'active': false,
    });
  }

  /// Restaura uma administradora da lixeira
  Future<void> restoreFromTrash(String id) async {
    await _collection.doc(id).update({
      'deletedAt': FieldValue.delete(),
      'active': true,
    });
  }

  /// Exclusão física permanente (incluindo subcoleções)
  Future<void> permanentDeleteAdministrator(String id) async {
    final adminRef = _collection.doc(id);

    // 1. Limpa condomínios e suas subcoleções
    final condosSnapshot = await adminRef.collection('condominiums').get();
    for (final condoDoc in condosSnapshot.docs) {
      // Blocos
      final blocksSnapshot = await condoDoc.reference.collection('blocks').get();
      for (final blockDoc in blocksSnapshot.docs) {
        // Apartamentos
        final aptsSnapshot = await blockDoc.reference.collection('apartments').get();
        for (final aptDoc in aptsSnapshot.docs) {
          // Leituras
          final readingsSnapshot = await aptDoc.reference.collection('readings').get();
          for (final readDoc in readingsSnapshot.docs) {
            await readDoc.reference.delete();
          }
          await aptDoc.reference.delete();
        }
        await blockDoc.reference.delete();
      }

      // Usuários do condomínio
      final usersSnapshot = await condoDoc.reference.collection('users').get();
      for (final userDoc in usersSnapshot.docs) {
        await userDoc.reference.delete();
      }

      await condoDoc.reference.delete();
    }

    // 2. Apaga o documento principal da administradora
    await adminRef.delete();
  }

  Future<void> deleteAdministrator(String id) async {
    await moveToTrash(id);
  }
}
