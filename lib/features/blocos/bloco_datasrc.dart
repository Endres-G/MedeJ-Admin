import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';

class BlockFirestoreDataSource {
  static const int _maxBatchSize = 450;

  final FirebaseFirestore _firestore;

  BlockFirestoreDataSource({FirebaseFirestore? firestore})
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
        .collection('blocks');
  }

  Future<List<BlockModel>> getBlocks(
    String administratorId,
    String condominiumId,
  ) async {
    final snapshot = await _collection(administratorId, condominiumId).get();

    return snapshot.docs
        .map((doc) => BlockModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<BlockModel> getBlock(
    String administratorId,
    String condominiumId,
    String blockId,
  ) async {
    final doc = await _collection(
      administratorId,
      condominiumId,
    ).doc(blockId).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('Bloco não encontrado.');
    }

    return BlockModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> createBlock(
    String administratorId,
    String condominiumId,
    BlockModel block,
  ) async {
    final docRef = await _collection(
      administratorId,
      condominiumId,
    ).add({...block.toMap(), 'createdAt': FieldValue.serverTimestamp()});

    return docRef.id;
  }

  Future<List<String>> createBlocksBatch(
    String administratorId,
    String condominiumId,
    List<BlockModel> blocks,
  ) async {
    if (blocks.isEmpty) return const [];

    final collection = _collection(administratorId, condominiumId);
    final createdIds = <String>[];

    for (var i = 0; i < blocks.length; i += _maxBatchSize) {
      final chunkEnd = (i + _maxBatchSize < blocks.length)
          ? i + _maxBatchSize
          : blocks.length;
      final chunk = blocks.sublist(i, chunkEnd);
      final batch = _firestore.batch();

      for (final block in chunk) {
        final docRef = collection.doc();
        createdIds.add(docRef.id);
        batch.set(docRef, {
          ...block.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }

    return createdIds;
  }

  Future<void> updateBlock(
    String administratorId,
    String condominiumId,
    BlockModel block,
  ) async {
    await _collection(
      administratorId,
      condominiumId,
    ).doc(block.id).update(block.toMap());
  }

  Future<void> deleteBlock(
    String administratorId,
    String condominiumId,
    String blockId,
  ) async {
    await _collection(administratorId, condominiumId).doc(blockId).delete();
  }
}
