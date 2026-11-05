import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';
import 'package:mede_ja_admin/firebase_options.dart';

const String _secondaryAppName = 'SecondaryUserProvisioningApp';

const String _upperChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const String _lowerChars = 'abcdefghijkmnopqrstuvwxyz';
const String _digitChars = '23456789';
const String _symbolChars = '@#%&*!';

/// Gera uma senha temporária criptograficamente forte sem caracteres ambíguos
/// (como 0/O ou 1/l/I) para facilitar a digitação no primeiro acesso mobile.
String generateTemporaryPassword({int length = 10, Random? random}) {
  final effectiveLength = length < 8 ? 8 : length;
  final rng = random ?? Random.secure();

  const allChars = '$_upperChars$_lowerChars$_digitChars$_symbolChars';

  final chars = <String>[
    _upperChars[rng.nextInt(_upperChars.length)],
    _lowerChars[rng.nextInt(_lowerChars.length)],
    _digitChars[rng.nextInt(_digitChars.length)],
    _symbolChars[rng.nextInt(_symbolChars.length)],
  ];

  while (chars.length < effectiveLength) {
    chars.add(allChars[rng.nextInt(allChars.length)]);
  }

  for (var i = chars.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = chars[i];
    chars[i] = chars[j];
    chars[j] = tmp;
  }

  return chars.join();
}

/// Valida uma senha temporária informada ou gerada no formulário.
String? validateTemporaryPassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Informe ou gere uma senha temporária.';
  }
  if (value.contains(RegExp(r'\s'))) {
    return 'A senha não pode conter espaços.';
  }
  if (value.length < 8) {
    return 'A senha temporária deve ter no mínimo 8 caracteres.';
  }
  if (!RegExp(r'[A-Za-z]').hasMatch(value) || !RegExp(r'\d').hasMatch(value)) {
    return 'Inclua letras e números na senha temporária.';
  }
  return null;
}

class ProvisionedUserCredentials {
  final UserModel user;
  final String temporaryPassword;
  final String condominiumId;
  final String condominiumName;
  final String? administratorName;

  const ProvisionedUserCredentials({
    required this.user,
    required this.temporaryPassword,
    required this.condominiumId,
    required this.condominiumName,
    this.administratorName,
  });

  String buildShareableSummary() {
    final buffer = StringBuffer()
      ..writeln('Acesso MedeJá — Primeiro Acesso')
      ..writeln('Condomínio: $condominiumName');
    if (administratorName != null && administratorName!.trim().isNotEmpty) {
      buffer.writeln('Administradora: ${administratorName!.trim()}');
    }
    buffer
      ..writeln('Usuário: ${user.name}')
      ..writeln('E-mail: ${user.email}')
      ..writeln('Senha temporária: $temporaryPassword')
      ..writeln()
      ..write(
        'Importante: utilize esta senha temporária no primeiro login pelo '
        'aplicativo MedeJá e defina uma nova senha pessoal em seguida.',
      );
    return buffer.toString();
  }
}

abstract class UserAuthProvisioner {
  /// Cria a conta no Firebase Authentication sem encerrar a sessão atual do
  /// administrador e executa [persistUser] com o UID gerado. Caso a gravação
  /// no Firestore falhe, desfaz a criação no Auth para evitar contas órfãs.
  Future<T> provisionAndPersist<T>({
    required String name,
    required String email,
    required String temporaryPassword,
    required Future<T> Function(String authUid) persistUser,
  });

  /// Dispara o e-mail oficial do Firebase para redefinição de senha.
  Future<void> sendPasswordResetEmail(String email);
}

class FirebaseUserAuthProvisioner implements UserAuthProvisioner {
  final FirebaseAuth? _primaryAuth;

  FirebaseUserAuthProvisioner({FirebaseAuth? primaryAuth})
    : _primaryAuth = primaryAuth;

  Future<FirebaseApp> _obtainSecondaryApp() async {
    try {
      return Firebase.app(_secondaryAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _secondaryAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  @override
  Future<T> provisionAndPersist<T>({
    required String name,
    required String email,
    required String temporaryPassword,
    required Future<T> Function(String authUid) persistUser,
  }) async {
    final secondaryApp = await _obtainSecondaryApp();
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      await secondaryAuth.setPersistence(Persistence.NONE);
    } catch (_) {
      // Ambientes não-web ignoram setPersistence(Persistence.NONE).
    }

    UserCredential? credential;
    try {
      credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: temporaryPassword,
      );

      final createdAuthUser = credential.user;
      if (createdAuthUser == null || createdAuthUser.uid.isEmpty) {
        throw Exception(
          'Não foi possível obter o identificador (UID) da conta criada.',
        );
      }

      try {
        await createdAuthUser.updateDisplayName(name.trim());
      } catch (_) {
        // Não interrompe o fluxo caso a atualização de displayName falhe.
      }

      try {
        return await persistUser(createdAuthUser.uid);
      } catch (firestoreError) {
        try {
          await createdAuthUser.delete();
        } catch (_) {
          // Melhor esforço para evitar conta órfã no Firebase Auth.
        }
        rethrow;
      }
    } finally {
      try {
        await secondaryAuth.signOut();
      } catch (_) {}
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _primaryAuth ?? FirebaseAuth.instance;
    await auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }
}

final userAuthProvisionerProvider = Provider<UserAuthProvisioner>((ref) {
  return FirebaseUserAuthProvisioner();
});

String formatAuthAndFirestoreError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Este e-mail já possui uma conta cadastrada no Firebase Authentication.';
      case 'invalid-email':
        return 'O formato do e-mail informado é inválido.';
      case 'weak-password':
        return 'A senha temporária é considerada fraca pelo Firebase. Gere uma senha mais forte.';
      case 'operation-not-allowed':
        return 'O login por e-mail/senha não está habilitado no Firebase Authentication.';
      case 'user-not-found':
        return 'Nenhuma conta encontrada no Firebase Authentication para este e-mail.';
      case 'too-many-requests':
        return 'Muitas solicitações seguidas. Aguarde alguns instantes e tente novamente.';
      case 'network-request-failed':
        return 'Falha de conexão com o Firebase. Verifique sua internet e tente novamente.';
      default:
        return 'Erro de autenticação (${error.code}): ${error.message ?? 'falha inesperada.'}';
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Permissão negada no Firestore (${error.code}). Verifique as regras de segurança.';
      case 'unavailable':
        return 'Serviço do Firebase indisponível no momento. Verifique sua conexão e tente novamente.';
      case 'not-found':
        return 'Registro não encontrado no Firestore.';
      default:
        return 'Erro no Firebase (${error.code}): ${error.message ?? 'falha inesperada.'}';
    }
  }

  final raw = error.toString();
  if (raw.startsWith('Exception: ')) {
    return raw.substring('Exception: '.length);
  }
  return raw;
}
