import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/leituras/reading_model.dart';

class ApartmentReadingItem {
  final ApartmentModel apartment;
  final BlockModel block;
  final ReadingModel? latestGasReading;
  final ReadingModel? latestWaterReading;
  final List<ReadingModel> history;

  const ApartmentReadingItem({
    required this.apartment,
    required this.block,
    this.latestGasReading,
    this.latestWaterReading,
    this.history = const [],
  });

  /// Retorna a leitura mais recente de acordo com o tipo solicitado.
  ReadingModel? latestReadingFor(MeterType type) =>
      type == MeterType.water ? latestWaterReading : latestGasReading;

  /// Getter de compatibilidade (retorna a de Gás por padrão).
  ReadingModel? get latestReading => latestGasReading;

  bool hasReadingFor(MeterType type) => latestReadingFor(type) != null;
  bool get hasReading => hasReadingFor(MeterType.gas);
}

class CondominiumReadingsOverview {
  final String condominiumId;
  final String condominiumName;
  final String administratorId;
  final String administratorName;
  final List<ApartmentReadingItem> apartments;
  final DateTime? latestGasReadingDate;
  final DateTime? latestWaterReadingDate;

  const CondominiumReadingsOverview({
    required this.condominiumId,
    required this.condominiumName,
    required this.administratorId,
    required this.administratorName,
    required this.apartments,
    this.latestGasReadingDate,
    this.latestWaterReadingDate,
  });

  int get totalApartments => apartments.length;

  int measuredCount(MeterType type) =>
      apartments.where((a) => a.hasReadingFor(type)).length;

  int pendingCount(MeterType type) => totalApartments - measuredCount(type);

  double coverageFor(MeterType type) =>
      totalApartments == 0 ? 0.0 : (measuredCount(type) / totalApartments);

  DateTime? latestDateFor(MeterType type) =>
      type == MeterType.water ? latestWaterReadingDate : latestGasReadingDate;

  // Getters para compatibilidade com implementações existentes
  int get measuredApartments => measuredCount(MeterType.gas);
  int get pendingApartments => pendingCount(MeterType.gas);
  double get coveragePercentage => coverageFor(MeterType.gas);
  DateTime? get latestGlobalReadingDate => latestGasReadingDate;
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

  /// Busca a última leitura registrada para um apartamento (opcionalmente filtrando por tipo)
  Future<ReadingModel?> getLatestReadingForApartment({
    required String administratorId,
    required String condominiumId,
    required String blockId,
    required String apartmentId,
    MeterType? meterType,
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
    ).orderBy('readAt', descending: true).limit(20).get();

    if (query.docs.isEmpty) return null;

    final models = query.docs.map((doc) {
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
    });

    if (meterType != null) {
      return models.where((r) => r.meterType == meterType).firstOrNull;
    }
    return models.firstOrNull;
  }

  /// Busca histórico de leituras de um apartamento
  Future<List<ReadingModel>> getReadingsHistoryForApartment({
    required String administratorId,
    required String condominiumId,
    required String blockId,
    required String apartmentId,
    MeterType? meterType,
    String? apartmentName,
    String? blockName,
    String? condominiumName,
    String? administratorName,
    int limit = 50,
  }) async {
    final query = await _readingsCollection(
      administratorId: administratorId,
      condominiumId: condominiumId,
      blockId: blockId,
      apartmentId: apartmentId,
    ).orderBy('readAt', descending: true).limit(limit).get();

    final all = query.docs.map((doc) {
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

    if (meterType != null) {
      return all.where((r) => r.meterType == meterType).toList();
    }
    return all;
  }

  /// Busca a visão consolidada de leituras de todos os apartamentos de um condomínio (Gás e Água)
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
    DateTime? globalLatestGasDate;
    DateTime? globalLatestWaterDate;

    for (final block in blocks) {
      final aptsCol = blocksCol.doc(block.id).collection('apartments');
      final aptsSnapshot = await aptsCol.get();
      final apartments = aptsSnapshot.docs
          .map((doc) => ApartmentModel.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => naturalCompare(a.name, b.name));

      for (final apt in apartments) {
        final readingsQuery = await _readingsCollection(
          administratorId: administratorId,
          condominiumId: condominiumId,
          blockId: block.id,
          apartmentId: apt.id,
        ).orderBy('readAt', descending: true).limit(20).get();

        final recentReadings = readingsQuery.docs.map((d) {
          return ReadingModel.fromFirestore(
            d,
            apartmentId: apt.id,
            apartmentName: apt.name,
            blockId: block.id,
            blockName: block.name,
            condominiumId: condominiumId,
            condominiumName: condominiumName,
            administratorId: administratorId,
            administratorName: administratorName,
          );
        }).toList();

        ReadingModel? latestGas;
        ReadingModel? latestWater;

        for (final r in recentReadings) {
          if (r.meterType == MeterType.gas && latestGas == null) {
            latestGas = r;
          } else if (r.meterType == MeterType.water && latestWater == null) {
            latestWater = r;
          }
          if (latestGas != null && latestWater != null) break;
        }

        if (latestGas != null) {
          if (globalLatestGasDate == null ||
              latestGas.readAt.isAfter(globalLatestGasDate)) {
            globalLatestGasDate = latestGas.readAt;
          }
        }
        if (latestWater != null) {
          if (globalLatestWaterDate == null ||
              latestWater.readAt.isAfter(globalLatestWaterDate)) {
            globalLatestWaterDate = latestWater.readAt;
          }
        }

        apartmentItems.add(
          ApartmentReadingItem(
            apartment: apt,
            block: block,
            latestGasReading: latestGas,
            latestWaterReading: latestWater,
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
      latestGasReadingDate: globalLatestGasDate,
      latestWaterReadingDate: globalLatestWaterDate,
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
