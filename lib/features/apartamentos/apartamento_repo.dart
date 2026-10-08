import 'package:mede_ja_admin/features/apartamentos/apartamento_datasrc.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';

class ApartmentRepository {
  final ApartmentFirestoreDataSource _dataSource;

  ApartmentRepository({ApartmentFirestoreDataSource? dataSource})
    : _dataSource = dataSource ?? ApartmentFirestoreDataSource();

  Future<List<ApartmentModel>> getApartments(
    String administratorId,
    String condominiumId,
    String blockId,
  ) {
    return _dataSource.getApartments(administratorId, condominiumId, blockId);
  }

  Future<ApartmentModel> getApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    String apartmentId,
  ) {
    return _dataSource.getApartment(
      administratorId,
      condominiumId,
      blockId,
      apartmentId,
    );
  }

  Future<String> createApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    ApartmentModel apartment,
  ) {
    return _dataSource.createApartment(
      administratorId,
      condominiumId,
      blockId,
      apartment,
    );
  }

  Future<void> updateApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    ApartmentModel apartment,
  ) {
    return _dataSource.updateApartment(
      administratorId,
      condominiumId,
      blockId,
      apartment,
    );
  }

  Future<void> deleteApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    String apartmentId,
  ) {
    return _dataSource.deleteApartment(
      administratorId,
      condominiumId,
      blockId,
      apartmentId,
    );
  }
}
