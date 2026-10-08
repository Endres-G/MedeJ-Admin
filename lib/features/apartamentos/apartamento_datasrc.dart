import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';

class ApartmentFirestoreDataSource {
  final FirebaseFirestore _firestore;

  ApartmentFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(
    String administratorId,
    String condominiumId,
    String blockId,
  ) {
    return _firestore
        .collection('administrators')
        .doc(administratorId)
        .collection('condominiums')
        .doc(condominiumId)
        .collection('blocks')
        .doc(blockId)
        .collection('apartments');
  }

  Future<List<ApartmentModel>> getApartments(
    String administratorId,
    String condominiumId,
    String blockId,
  ) async {
    final snapshot = await _collection(
      administratorId,
      condominiumId,
      blockId,
    ).get();

    return snapshot.docs
        .map((doc) => ApartmentModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<ApartmentModel> getApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    String apartmentId,
  ) async {
    final doc = await _collection(
      administratorId,
      condominiumId,
      blockId,
    ).doc(apartmentId).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('Apartamento não encontrado.');
    }

    return ApartmentModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> createApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    ApartmentModel apartment,
  ) async {
    final docRef = await _collection(
      administratorId,
      condominiumId,
      blockId,
    ).add({...apartment.toMap(), 'createdAt': FieldValue.serverTimestamp()});

    return docRef.id;
  }

  Future<void> updateApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    ApartmentModel apartment,
  ) async {
    await _collection(
      administratorId,
      condominiumId,
      blockId,
    ).doc(apartment.id).update(apartment.toMap());
  }

  Future<void> deleteApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    String apartmentId,
  ) async {
    await _collection(
      administratorId,
      condominiumId,
      blockId,
    ).doc(apartmentId).delete();
  }
}
