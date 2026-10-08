import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'auth_repo.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.read(authRepositoryProvider));
  },
);

class AuthState {
  final bool loading;
  final String? error;

  const AuthState({this.loading = false, this.error});

  AuthState copyWith({bool? loading, String? error, bool clearError = false}) {
    return AuthState(
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState());

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      await _repository.signIn(email: email, password: password);

      state = state.copyWith(loading: false, clearError: true);

      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _mapError(e));

      return false;
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
  }

  String _mapError(Object error) {
    final message = error.toString();

    if (message.contains('invalid-credential')) {
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

    return 'Não foi possível realizar o login.';
  }
}
