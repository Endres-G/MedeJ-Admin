import 'package:firebase_auth/firebase_auth.dart';
import 'auth_datasrc.dart';

class AuthRepository {
  final AuthFirebaseDataSource _dataSource;

  AuthRepository({AuthFirebaseDataSource? dataSource})
    : _dataSource = dataSource ?? AuthFirebaseDataSource();

  User? get currentUser => _dataSource.firebaseUser;

  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _dataSource.signIn(email: email, password: password);
  }

  Future<void> signOut() {
    return _dataSource.signOut();
  }
}
