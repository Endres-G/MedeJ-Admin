import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';

class ApartmentFirestoreDataSource {
  static const int _maxBatchSize = 450;

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

  Future<List<String>> createApartmentsBatch(
    String administratorId,
    String condominiumId,
    String blockId,
    List<ApartmentModel> apartments,
  ) async {
    if (apartments.isEmpty) return const [];

    final collection = _collection(administratorId, condominiumId, blockId);
    final createdIds = <String>[];

    for (var i = 0; i < apartments.length; i += _maxBatchSize) {
      final chunkEnd = (i + _maxBatchSize < apartments.length)
          ? i + _maxBatchSize
          : apartments.length;
      final chunk = apartments.sublist(i, chunkEnd);
      final batch = _firestore.batch();

      for (final apartment in chunk) {
        final docRef = collection.doc();
        createdIds.add(docRef.id);
        batch.set(docRef, {
          ...apartment.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }

    return createdIds;
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
