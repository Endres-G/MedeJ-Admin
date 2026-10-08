import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';

class CondominiumFirestoreDataSource {
  final FirebaseFirestore _firestore;

  CondominiumFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(
    String administratorId,
  ) {
    return _firestore
        .collection('administrators')
        .doc(administratorId)
        .collection('condominiums');
  }

  Future<List<CondominiumModel>> getCondominiumsByAdministrator(
    String administratorId,
  ) async {
    final snapshot = await _collection(administratorId).get();

    return snapshot.docs
        .map((doc) => CondominiumModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<CondominiumModel> getCondominium(
    String administratorId,
    String condominiumId,
  ) async {
    final doc = await _collection(administratorId).doc(condominiumId).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('Condomínio não encontrado.');
    }

    return CondominiumModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> createCondominium(
    String administratorId,
    CondominiumModel condominium,
  ) async {
    final docRef = await _collection(
      administratorId,
    ).add({...condominium.toMap(), 'createdAt': FieldValue.serverTimestamp()});

    return docRef.id;
  }

  Future<void> updateCondominium(
    String administratorId,
    CondominiumModel condominium,
  ) async {
    await _collection(
      administratorId,
    ).doc(condominium.id).update(condominium.toMap());
  }

  Future<void> deleteCondominium(
    String administratorId,
    String condominiumId,
  ) async {
    await _collection(administratorId).doc(condominiumId).delete();
  }
}
