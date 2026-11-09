import 'package:mede_ja_admin/features/users/user_datasrc.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';

class UserRepository {
  final UserFirestoreDataSource _dataSource;

  UserRepository({UserFirestoreDataSource? dataSource})
    : _dataSource = dataSource ?? UserFirestoreDataSource();

  Future<List<UserModel>> getUsers(
    String administratorId,
    String condominiumId, {
    bool includeDeleted = false,
  }) {
    return _dataSource.getUsers(
      administratorId,
      condominiumId,
      includeDeleted: includeDeleted,
    );
  }

  Future<List<UserModel>> getDeletedUsers(
    String administratorId,
    String condominiumId,
  ) {
    return _dataSource.getDeletedUsers(administratorId, condominiumId);
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

  Future<void> saveUserWithId(
    String administratorId,
    String condominiumId,
    String userId,
    UserModel user,
  ) {
    return _dataSource.saveUserWithId(
      administratorId,
      condominiumId,
      userId,
      user,
    );
  }

  Future<void> updateUser(
    String administratorId,
    String condominiumId,
    UserModel user,
  ) {
    return _dataSource.updateUser(administratorId, condominiumId, user);
  }

  Future<void> moveToTrash(
    String administratorId,
    String condominiumId,
    String userId,
  ) {
    return _dataSource.moveToTrash(administratorId, condominiumId, userId);
  }

  Future<void> restoreFromTrash(
    String administratorId,
    String condominiumId,
    String userId,
  ) {
    return _dataSource.restoreFromTrash(administratorId, condominiumId, userId);
  }

  Future<void> permanentDeleteUser(
    String administratorId,
    String condominiumId,
    String userId,
  ) {
    return _dataSource.permanentDeleteUser(administratorId, condominiumId, userId);
  }

  Future<void> deleteUser(
    String administratorId,
    String condominiumId,
    String userId,
  ) {
    return _dataSource.deleteUser(administratorId, condominiumId, userId);
  }
}
