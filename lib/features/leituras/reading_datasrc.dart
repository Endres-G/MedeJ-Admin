import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/leituras/reading_model.dart';

class ApartmentReadingItem {
  final ApartmentModel apartment;
  final BlockModel block;
  final ReadingModel? latestReading;
  final List<ReadingModel> history;

  const ApartmentReadingItem({
    required this.apartment,
    required this.block,
    this.latestReading,
    this.history = const [],
  });

  bool get hasReading => latestReading != null;
}

class CondominiumReadingsOverview {
  final String condominiumId;
  final String condominiumName;
  final String administratorId;
  final String administratorName;
  final List<ApartmentReadingItem> apartments;
  final DateTime? latestGlobalReadingDate;

  const CondominiumReadingsOverview({
    required this.condominiumId,
    required this.condominiumName,
    required this.administratorId,
    required this.administratorName,
    required this.apartments,
    this.latestGlobalReadingDate,
  });

  int get totalApartments => apartments.length;
  int get measuredApartments => apartments.where((a) => a.hasReading).length;
  int get pendingApartments => totalApartments - measuredApartments;
  double get coveragePercentage =>
      totalApartments == 0 ? 0.0 : (measuredApartments / totalApartments);
}

class ReadingFirestoreDataSource {
  final FirebaseFirestore? _injectedFirestore;

  ReadingFirestoreDataSource({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _readingsCollection({
    required String administratorId,
    required String condominiumId,
    required String blockId,
    required String apartmentId,
  }) {
    return _firestore
        .collection('administrators')
        .doc(administratorId)
        .collection('condominiums')
        .doc(condominiumId)
        .collection('blocks')
        .doc(blockId)
        .collection('apartments')
        .doc(apartmentId)
        .collection('readings');
  }

  /// Busca a última leitura registrada para um apartamento
  Future<ReadingModel?> getLatestReadingForApartment({
    required String administratorId,
    required String condominiumId,
    required String blockId,
    required String apartmentId,
    String? apartmentName,
    String? blockName,
    String? condominiumName,
    String? administratorName,
  }) async {
    final query = await _readingsCollection(
      administratorId: administratorId,
      condominiumId: condominiumId,
      blockId: blockId,
      apartmentId: apartmentId,
    ).orderBy('readAt', descending: true).limit(1).get();

    if (query.docs.isEmpty) return null;

    return ReadingModel.fromFirestore(
      query.docs.first,
      apartmentId: apartmentId,
      apartmentName: apartmentName,
      blockId: blockId,
      blockName: blockName,
      condominiumId: condominiumId,
      condominiumName: condominiumName,
      administratorId: administratorId,
      administratorName: administratorName,
    );
  }

  /// Busca histórico de leituras de um apartamento
  Future<List<ReadingModel>> getReadingsHistoryForApartment({
    required String administratorId,
    required String condominiumId,
    required String blockId,
    required String apartmentId,
    String? apartmentName,
    String? blockName,
    String? condominiumName,
    String? administratorName,
    int limit = 20,
  }) async {
    final query = await _readingsCollection(
      administratorId: administratorId,
      condominiumId: condominiumId,
      blockId: blockId,
      apartmentId: apartmentId,
    ).orderBy('readAt', descending: true).limit(limit).get();

    return query.docs.map((doc) {
      return ReadingModel.fromFirestore(
        doc,
        apartmentId: apartmentId,
        apartmentName: apartmentName,
        blockId: blockId,
        blockName: blockName,
        condominiumId: condominiumId,
        condominiumName: condominiumName,
        administratorId: administratorId,
        administratorName: administratorName,
      );
    }).toList();
  }

  /// Busca a visão consolidada de leituras de todos os apartamentos de um condomínio
  Future<CondominiumReadingsOverview> getCondominiumReadingsOverview({
    required String administratorId,
    required String administratorName,
    required String condominiumId,
    required String condominiumName,
  }) async {
    final blocksCol = _firestore
        .collection('administrators')
        .doc(administratorId)
        .collection('condominiums')
        .doc(condominiumId)
        .collection('blocks');

    final blocksSnapshot = await blocksCol.get();
    final blocks = blocksSnapshot.docs
        .map((doc) => BlockModel.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => naturalCompare(a.name, b.name));

    final apartmentItems = <ApartmentReadingItem>[];
    DateTime? globalLatestDate;

    for (final block in blocks) {
      final aptsCol = blocksCol.doc(block.id).collection('apartments');
      final aptsSnapshot = await aptsCol.get();
      final apartments = aptsSnapshot.docs
          .map((doc) => ApartmentModel.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => naturalCompare(a.name, b.name));

      for (final apt in apartments) {
        final latest = await getLatestReadingForApartment(
          administratorId: administratorId,
          condominiumId: condominiumId,
          blockId: block.id,
          apartmentId: apt.id,
          apartmentName: apt.name,
          blockName: block.name,
          condominiumName: condominiumName,
          administratorName: administratorName,
        );

        if (latest != null) {
          if (globalLatestDate == null || latest.readAt.isAfter(globalLatestDate)) {
            globalLatestDate = latest.readAt;
          }
        }

        apartmentItems.add(
          ApartmentReadingItem(
            apartment: apt,
            block: block,
            latestReading: latest,
          ),
        );
      }
    }

    return CondominiumReadingsOverview(
      condominiumId: condominiumId,
      condominiumName: condominiumName,
      administratorId: administratorId,
      administratorName: administratorName,
      apartments: apartmentItems,
      latestGlobalReadingDate: globalLatestDate,
    );
  }

  /// Salva ou sincroniza uma leitura manualmente (útil para testes ou contingência)
  Future<String> addReading({
    required String administratorId,
    required String condominiumId,
    required String blockId,
    required String apartmentId,
    required ReadingModel reading,
  }) async {
    final docRef = await _readingsCollection(
      administratorId: administratorId,
      condominiumId: condominiumId,
      blockId: blockId,
      apartmentId: apartmentId,
    ).add(reading.toMap());

    return docRef.id;
  }
}
