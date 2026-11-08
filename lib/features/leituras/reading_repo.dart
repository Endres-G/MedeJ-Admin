import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mede_ja_admin/features/leituras/reading_datasrc.dart';
import 'package:mede_ja_admin/features/leituras/reading_model.dart';

final readingDataSourceProvider = Provider<ReadingFirestoreDataSource>((ref) {
  return ReadingFirestoreDataSource();
});

final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  return ReadingRepository(ref.watch(readingDataSourceProvider));
});

class ReadingRepository {
  final ReadingFirestoreDataSource _dataSource;

  ReadingRepository(this._dataSource);

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
  }) {
    return _dataSource.getLatestReadingForApartment(
      administratorId: administratorId,
      condominiumId: condominiumId,
      blockId: blockId,
      apartmentId: apartmentId,
      meterType: meterType,
      apartmentName: apartmentName,
      blockName: blockName,
      condominiumName: condominiumName,
      administratorName: administratorName,
    );
  }

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
  }) {
    return _dataSource.getReadingsHistoryForApartment(
      administratorId: administratorId,
      condominiumId: condominiumId,
      blockId: blockId,
      apartmentId: apartmentId,
      meterType: meterType,
      apartmentName: apartmentName,
      blockName: blockName,
      condominiumName: condominiumName,
      administratorName: administratorName,
      limit: limit,
    );
  }

  Future<CondominiumReadingsOverview> getCondominiumReadingsOverview({
    required String administratorId,
    required String administratorName,
    required String condominiumId,
    required String condominiumName,
    DateTime? referenceMonth,
  }) {
    return _dataSource.getCondominiumReadingsOverview(
      administratorId: administratorId,
      administratorName: administratorName,
      condominiumId: condominiumId,
      condominiumName: condominiumName,
      referenceMonth: referenceMonth,
    );
  }

  Future<String> addReading({
    required String administratorId,
    required String condominiumId,
    required String blockId,
    required String apartmentId,
    required ReadingModel reading,
  }) {
    return _dataSource.addReading(
      administratorId: administratorId,
      condominiumId: condominiumId,
      blockId: blockId,
      apartmentId: apartmentId,
      reading: reading,
    );
  }
}
