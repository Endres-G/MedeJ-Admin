import 'package:mede_ja_admin/features/condominos/condominio_datasrc.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';

class CondominiumRepository {
  final CondominiumFirestoreDataSource _dataSource;

  CondominiumRepository({CondominiumFirestoreDataSource? dataSource})
    : _dataSource = dataSource ?? CondominiumFirestoreDataSource();

  Future<List<CondominiumModel>> getCondominiumsByAdministrator(
    String administratorId,
  ) {
    return _dataSource.getCondominiumsByAdministrator(administratorId);
  }

  Future<CondominiumModel> getCondominium(
    String administratorId,
    String condominiumId,
  ) {
    return _dataSource.getCondominium(administratorId, condominiumId);
  }

  Future<String> createCondominium(
    String administratorId,
    CondominiumModel condominium,
  ) {
    return _dataSource.createCondominium(administratorId, condominium);
  }

  Future<void> updateCondominium(
    String administratorId,
    CondominiumModel condominium,
  ) {
    return _dataSource.updateCondominium(administratorId, condominium);
  }

  Future<void> deleteCondominium(String administratorId, String condominiumId) {
    return _dataSource.deleteCondominium(administratorId, condominiumId);
  }
}
