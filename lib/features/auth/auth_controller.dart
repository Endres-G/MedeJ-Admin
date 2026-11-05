import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mede_ja_admin/features/auth/account_role_datasrc.dart';

import 'auth_repo.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.watch(authRepositoryProvider),
      ref.watch(accountRoleRepositoryProvider),
    );
  },
);

enum AuthSessionStatus {
  checking,
  unauthenticated,
  authenticatedAdmin,
}

class AuthState {
  final AuthSessionStatus status;
  final bool loading;
  final AccountRoleProfile? currentProfile;
  final String? error;

  const AuthState({
    this.status = AuthSessionStatus.unauthenticated,
    this.loading = false,
    this.currentProfile,
    this.error,
  });

  bool get isAuthorizedAdmin =>
      status == AuthSessionStatus.authenticatedAdmin &&
      currentProfile != null &&
      currentProfile!.isAdmin &&
      currentProfile!.active;

  AuthState copyWith({
    AuthSessionStatus? status,
    bool? loading,
    AccountRoleProfile? currentProfile,
    bool clearProfile = false,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      loading: loading ?? this.loading,
      currentProfile: clearProfile
          ? null
          : (currentProfile ?? this.currentProfile),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  static const String nonAdminAccessDeniedMessage =
      'Acesso restrito a administradores. Esta conta possui perfil Comum/Operacional e deve ser utilizada apenas no aplicativo mobile MedeJá.';

  static const String inactiveAccountMessage =
      'Esta conta está desativada. Entre em contato com um administrador.';

  final AuthRepository _repository;
  final AccountRoleRepository _roleRepository;
  StreamSubscription<User?>? _authSubscription;
  bool _isExplicitAuthOperationInProgress = false;

  AuthController(this._repository, this._roleRepository)
    : super(
        AuthState(
          status: _hasInitialUser(_repository)
              ? AuthSessionStatus.checking
              : AuthSessionStatus.unauthenticated,
          loading: _hasInitialUser(_repository),
        ),
      ) {
    _listenToAuthChanges();
  }

  static bool _hasInitialUser(AuthRepository repository) {
    try {
      return repository.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  void _listenToAuthChanges() {
    try {
      _authSubscription = _repository.authStateChanges.listen((user) {
        if (_isExplicitAuthOperationInProgress || !mounted) return;

        if (user == null) {
          state = state.copyWith(
            status: AuthSessionStatus.unauthenticated,
            loading: false,
            clearProfile: true,
          );
          return;
        }

        _verifyRestoredSession(user);
      });
    } catch (_) {
      // Ambiente sem Firebase inicializado (ex.: testes de widget isolados).
    }
  }

  Future<void> _verifyRestoredSession(User user) async {
    if (!mounted) return;

    // Se já validou o mesmo UID nesta sessão, evita reconsulta desnecessária.
    if (state.isAuthorizedAdmin && state.currentProfile?.uid == user.uid) {
      return;
    }

    state = state.copyWith(
      status: AuthSessionStatus.checking,
      loading: true,
      clearError: true,
    );

    try {
      final profile = await _roleRepository.resolveOrBootstrapSessionProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );

      if (!mounted) return;

      if (!profile.active) {
        await _forceSignOutSilently();
        if (!mounted) return;
        state = const AuthState(
          status: AuthSessionStatus.unauthenticated,
          loading: false,
          error: inactiveAccountMessage,
        );
        return;
      }

      if (!profile.isAdmin) {
        await _forceSignOutSilently();
        if (!mounted) return;
        state = const AuthState(
          status: AuthSessionStatus.unauthenticated,
          loading: false,
          error: nonAdminAccessDeniedMessage,
        );
        return;
      }

      state = AuthState(
        status: AuthSessionStatus.authenticatedAdmin,
        loading: false,
        currentProfile: profile,
      );
    } catch (e) {
      await _forceSignOutSilently();
      if (!mounted) return;
      state = AuthState(
        status: AuthSessionStatus.unauthenticated,
        loading: false,
        error: _mapError(e),
      );
    }
  }

  Future<void> _forceSignOutSilently() async {
    _isExplicitAuthOperationInProgress = true;
    try {
      await _repository.signOut();
    } catch (_) {
    } finally {
      _isExplicitAuthOperationInProgress = false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isExplicitAuthOperationInProgress = true;
    state = state.copyWith(
      status: AuthSessionStatus.checking,
      loading: true,
      clearError: true,
      clearProfile: true,
    );

    try {
      final credential = await _repository.signIn(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null || user.uid.isEmpty) {
        throw Exception('Não foi possível validar o usuário autenticado.');
      }

      final profile = await _roleRepository.resolveOrBootstrapSessionProfile(
        uid: user.uid,
        email: user.email ?? email.trim(),
        displayName: user.displayName,
      );

      if (!profile.active) {
        await _repository.signOut();
        if (mounted) {
          state = const AuthState(
            status: AuthSessionStatus.unauthenticated,
            loading: false,
            error: inactiveAccountMessage,
          );
        }
        return false;
      }

      if (!profile.isAdmin) {
        await _repository.signOut();
        if (mounted) {
          state = const AuthState(
            status: AuthSessionStatus.unauthenticated,
            loading: false,
            error: nonAdminAccessDeniedMessage,
          );
        }
        return false;
      }

      if (mounted) {
        state = AuthState(
          status: AuthSessionStatus.authenticatedAdmin,
          loading: false,
          currentProfile: profile,
        );
      }
      return true;
    } catch (e) {
      try {
        if (_repository.currentUser != null) {
          await _repository.signOut();
        }
      } catch (_) {}

      if (mounted) {
        state = AuthState(
          status: AuthSessionStatus.unauthenticated,
          loading: false,
          error: _mapError(e),
        );
      }
      return false;
    } finally {
      _isExplicitAuthOperationInProgress = false;
    }
  }

  Future<void> logout() async {
    _isExplicitAuthOperationInProgress = true;
    try {
      await _repository.signOut();
    } finally {
      _isExplicitAuthOperationInProgress = false;
    }

    if (mounted) {
      state = const AuthState(
        status: AuthSessionStatus.unauthenticated,
        loading: false,
      );
    }
  }

  String _mapError(Object error) {
    final message = error.toString();

    if (message.contains('invalid-credential') ||
        message.contains('wrong-password') ||
        message.contains('user-not-found')) {
      return 'E-mail ou senha incorretos.';
    }

    if (message.contains('invalid-email')) {
      return 'Informe um e-mail válido.';
    }

    if (message.contains('user-disabled')) {
      return 'Este usuário está desativado.';
    }

    if (message.contains('too-many-requests')) {
      return 'Muitas tentativas. Tente novamente mais tarde.';
    }

    if (message.contains('permission-denied')) {
      return 'Sem permissão no Firestore para validar o perfil desta conta.';
    }

    return 'Não foi possível realizar o login.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
