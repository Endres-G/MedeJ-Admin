import 'package:mede_ja_admin/features/condominos/condominio_datasrc.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';

class CondominiumRepository {
  final CondominiumFirestoreDataSource _dataSource;

  CondominiumRepository({CondominiumFirestoreDataSource? dataSource})
    : _dataSource = dataSource ?? CondominiumFirestoreDataSource();

  Future<List<CondominiumModel>> getCondominiumsByAdministrator(
    String administratorId, {
    bool includeDeleted = false,
  }) {
    return _dataSource.getCondominiumsByAdministrator(
      administratorId,
      includeDeleted: includeDeleted,
    );
  }

  Future<List<CondominiumModel>> getDeletedCondominiumsByAdministrator(
    String administratorId,
  ) {
    return _dataSource.getDeletedCondominiumsByAdministrator(administratorId);
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

  Future<void> moveToTrash(String administratorId, String condominiumId) {
    return _dataSource.moveToTrash(administratorId, condominiumId);
  }

  Future<void> restoreFromTrash(String administratorId, String condominiumId) {
    return _dataSource.restoreFromTrash(administratorId, condominiumId);
  }

  Future<void> permanentDeleteCondominium(
    String administratorId,
    String condominiumId,
  ) {
    return _dataSource.permanentDeleteCondominium(
      administratorId,
      condominiumId,
    );
  }

  Future<void> deleteCondominium(String administratorId, String condominiumId) {
    return _dataSource.deleteCondominium(administratorId, condominiumId);
  }
}
