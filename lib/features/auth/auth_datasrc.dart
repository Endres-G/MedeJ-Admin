import 'package:firebase_auth/firebase_auth.dart';

class AuthFirebaseDataSource {
  final FirebaseAuth? _injectedAuth;

  AuthFirebaseDataSource({FirebaseAuth? auth}) : _injectedAuth = auth;

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  User? get firebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
