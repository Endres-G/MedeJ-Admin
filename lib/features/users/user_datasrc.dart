import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';

class UserFirestoreDataSource {
  final FirebaseFirestore _firestore;

  UserFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(
    String administratorId,
    String condominiumId,
  ) {
    return _firestore
        .collection('administrators')
        .doc(administratorId)
        .collection('condominiums')
        .doc(condominiumId)
        .collection('users');
  }

  Future<List<UserModel>> getUsers(
    String administratorId,
    String condominiumId,
  ) async {
    final snapshot = await _collection(administratorId, condominiumId).get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<UserModel> getUser(
    String administratorId,
    String condominiumId,
    String userId,
  ) async {
    final doc = await _collection(
      administratorId,
      condominiumId,
    ).doc(userId).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('Usuário não encontrado.');
    }

    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> createUser(
    String administratorId,
    String condominiumId,
    UserModel user,
  ) async {
    final docRef = await _collection(
      administratorId,
      condominiumId,
    ).add({...user.toMap(), 'createdAt': FieldValue.serverTimestamp()});

    return docRef.id;
  }

  Future<void> saveUserWithId(
    String administratorId,
    String condominiumId,
    String userId,
    UserModel user,
  ) async {
    await _collection(administratorId, condominiumId).doc(userId).set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUser(
    String administratorId,
    String condominiumId,
    UserModel user,
  ) async {
    await _collection(
      administratorId,
      condominiumId,
    ).doc(user.id).update(user.toMap());
  }

  Future<void> deleteUser(
    String administratorId,
    String condominiumId,
    String userId,
  ) async {
    await _collection(administratorId, condominiumId).doc(userId).delete();
  }
}
