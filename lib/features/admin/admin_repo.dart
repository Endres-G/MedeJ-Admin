import 'package:mede_ja_admin/features/admin/admin_datasrc.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';

class AdministratorRepository {
  final AdministratorFirestoreDataSource _dataSource;

  AdministratorRepository({AdministratorFirestoreDataSource? dataSource})
    : _dataSource = dataSource ?? AdministratorFirestoreDataSource();

  Future<List<AdministratorModel>> getAdministrators() {
    return _dataSource.getAdministrators();
  }

  Future<AdministratorModel> getAdministrator(String id) {
    return _dataSource.getAdministrator(id);
  }

  Future<String> createAdministrator(AdministratorModel administrator) {
    return _dataSource.createAdministrator(administrator);
  }

  Future<void> updateAdministrator(AdministratorModel administrator) {
    return _dataSource.updateAdministrator(administrator);
  }

  Future<void> deleteAdministrator(String id) {
    return _dataSource.deleteAdministrator(id);
  }
}
