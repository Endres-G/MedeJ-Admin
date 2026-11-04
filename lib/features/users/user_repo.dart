import 'package:mede_ja_admin/features/users/user_datasrc.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';

class UserRepository {
  final UserFirestoreDataSource _dataSource;

  UserRepository({UserFirestoreDataSource? dataSource})
    : _dataSource = dataSource ?? UserFirestoreDataSource();

  Future<List<UserModel>> getUsers(
    String administratorId,
    String condominiumId,
  ) {
    return _dataSource.getUsers(administratorId, condominiumId);
  }

  Future<UserModel> getUser(
    String administratorId,
    String condominiumId,
    String userId,
  ) {
    return _dataSource.getUser(administratorId, condominiumId, userId);
  }

  Future<String> createUser(
    String administratorId,
    String condominiumId,
    UserModel user,
  ) {
    return _dataSource.createUser(administratorId, condominiumId, user);
  }

  Future<void> updateUser(
    String administratorId,
    String condominiumId,
    UserModel user,
  ) {
    return _dataSource.updateUser(administratorId, condominiumId, user);
  }

  Future<void> deleteUser(
    String administratorId,
    String condominiumId,
    String userId,
  ) {
    return _dataSource.deleteUser(administratorId, condominiumId, userId);
  }
}
