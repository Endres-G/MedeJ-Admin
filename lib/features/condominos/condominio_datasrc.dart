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
    String administratorId, {
    bool includeDeleted = false,
  }) async {
    final snapshot = await _collection(administratorId).get();

    final list = snapshot.docs
        .map((doc) => CondominiumModel.fromMap(doc.id, doc.data()))
        .toList();

    if (!includeDeleted) {
      return list.where((c) => !c.isDeleted).toList();
    }
    return list;
  }

  Future<List<CondominiumModel>> getDeletedCondominiumsByAdministrator(
    String administratorId,
  ) async {
    final snapshot = await _collection(administratorId).get();

    return snapshot.docs
        .map((doc) => CondominiumModel.fromMap(doc.id, doc.data()))
        .where((c) => c.isDeleted)
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

  /// Move o condomínio para a lixeira (Soft Delete)
  Future<void> moveToTrash(
    String administratorId,
    String condominiumId,
  ) async {
    await _collection(administratorId).doc(condominiumId).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'active': false,
    });
  }

  /// Restaura o condomínio da lixeira
  Future<void> restoreFromTrash(
    String administratorId,
    String condominiumId,
  ) async {
    await _collection(administratorId).doc(condominiumId).update({
      'deletedAt': FieldValue.delete(),
      'active': true,
    });
  }

  /// Exclusão física permanente do condomínio e todas as suas subcoleções
  Future<void> permanentDeleteCondominium(
    String administratorId,
    String condominiumId,
  ) async {
    final condoRef = _collection(administratorId).doc(condominiumId);

    // 1. Limpa blocos, apartamentos e leituras
    final blocksSnapshot = await condoRef.collection('blocks').get();
    for (final blockDoc in blocksSnapshot.docs) {
      final aptsSnapshot = await blockDoc.reference.collection('apartments').get();
      for (final aptDoc in aptsSnapshot.docs) {
        final readingsSnapshot = await aptDoc.reference.collection('readings').get();
        for (final readDoc in readingsSnapshot.docs) {
          await readDoc.reference.delete();
        }
        await aptDoc.reference.delete();
      }
      await blockDoc.reference.delete();
    }

    // 2. Limpa usuários associados a este condomínio
    final usersSnapshot = await condoRef.collection('users').get();
    for (final userDoc in usersSnapshot.docs) {
      await userDoc.reference.delete();
    }

    // 3. Deleta o documento do condomínio
    await condoRef.delete();
  }

  Future<void> deleteCondominium(
    String administratorId,
    String condominiumId,
  ) async {
    await moveToTrash(administratorId, condominiumId);
  }
}
