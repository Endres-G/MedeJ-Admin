import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';

class AdministratorFirestoreDataSource {
  final FirebaseFirestore _firestore;

  AdministratorFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('administrators');

  Future<List<AdministratorModel>> getAdministrators() async {
    final snapshot = await _collection.get();

    return snapshot.docs
        .map((doc) => AdministratorModel.fromMap(doc.id, doc.data()))
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

  Future<void> deleteAdministrator(String id) async {
    await _collection.doc(id).delete();
  }
}
