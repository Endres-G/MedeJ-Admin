import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamento_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';
import 'package:mede_ja_admin/features/auth/account_role_datasrc.dart';
import 'package:mede_ja_admin/features/auth/auth_controller.dart';
import 'package:mede_ja_admin/features/auth/auth_repo.dart';
import 'package:mede_ja_admin/features/auth/login_page.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_repo.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_repo.dart';
import 'package:mede_ja_admin/features/contas/contas_page.dart';
import 'package:mede_ja_admin/features/users/new_condominio_user_page.dart';
import 'package:mede_ja_admin/features/users/user_condominio_page.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';
import 'package:mede_ja_admin/features/users/user_provisioning_datasrc.dart';
import 'package:mede_ja_admin/features/users/user_repo.dart';

class _InMemoryAdminRepo implements AdministratorRepository {
  final List<AdministratorModel> admins;

  _InMemoryAdminRepo(this.admins);

  @override
  Future<List<AdministratorModel>> getAdministrators({bool includeDeleted = false}) async => List.of(admins);

  @override
  Future<List<AdministratorModel>> getDeletedAdministrators() async => [];

  @override
  Future<void> moveToTrash(String id) async {}

  @override
  Future<void> restoreFromTrash(String id) async {}

  @override
  Future<void> permanentDeleteAdministrator(String id) async {}

  @override
  Future<AdministratorModel> getAdministrator(String id) async =>
      admins.firstWhere((a) => a.id == id);

  @override
  Future<String> createAdministrator(AdministratorModel administrator) =>
      throw UnimplementedError();

  @override
  Future<void> updateAdministrator(AdministratorModel administrator) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAdministrator(String id) => throw UnimplementedError();
}

class _InMemoryCondoRepo implements CondominiumRepository {
  final Map<String, List<CondominiumModel>> condosByAdmin;

  _InMemoryCondoRepo(this.condosByAdmin);

  @override
  Future<List<CondominiumModel>> getCondominiumsByAdministrator(
    String administratorId,
  ) async => List.of(condosByAdmin[administratorId] ?? const []);

  @override
  Future<CondominiumModel> getCondominium(
    String administratorId,
    String condominiumId,
  ) async => (condosByAdmin[administratorId] ?? const []).firstWhere(
    (c) => c.id == condominiumId,
  );

  @override
  Future<String> createCondominium(
    String administratorId,
    CondominiumModel condominium,
  ) => throw UnimplementedError();

  @override
  Future<void> updateCondominium(
    String administratorId,
    CondominiumModel condominium,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteCondominium(
    String administratorId,
    String condominiumId,
  ) => throw UnimplementedError();
}

class _EmptyBlockRepo implements BlockRepository {
  @override
  Future<List<BlockModel>> getBlocks(
    String administratorId,
    String condominiumId,
  ) async => const [];

  @override
  Future<BlockModel> getBlock(
    String administratorId,
    String condominiumId,
    String blockId,
  ) => throw UnimplementedError();

  @override
  Future<String> createBlock(
    String administratorId,
    String condominiumId,
    BlockModel block,
  ) => throw UnimplementedError();

  @override
  Future<List<String>> createBlocksBatch(
    String administratorId,
    String condominiumId,
    List<BlockModel> blocks,
  ) => throw UnimplementedError();

  @override
  Future<void> updateBlock(
    String administratorId,
    String condominiumId,
    BlockModel block,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteBlock(
    String administratorId,
    String condominiumId,
    String blockId,
  ) => throw UnimplementedError();
}

class _EmptyApartmentRepo implements ApartmentRepository {
  @override
  Future<List<ApartmentModel>> getApartments(
    String administratorId,
    String condominiumId,
    String blockId,
  ) async => const [];

  @override
  Future<ApartmentModel> getApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    String apartmentId,
  ) => throw UnimplementedError();

  @override
  Future<String> createApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    ApartmentModel apartment,
  ) => throw UnimplementedError();

  @override
  Future<List<String>> createApartmentsBatch(
    String administratorId,
    String condominiumId,
    String blockId,
    List<ApartmentModel> apartments,
  ) => throw UnimplementedError();

  @override
  Future<void> updateApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    ApartmentModel apartment,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    String apartmentId,
  ) => throw UnimplementedError();
}

class _InMemoryUserRepo implements UserRepository {
  final Map<String, List<UserModel>> usersByCondo;

  _InMemoryUserRepo(this.usersByCondo);

  @override
  Future<List<UserModel>> getUsers(
    String administratorId,
    String condominiumId,
  ) async => List.of(usersByCondo[condominiumId] ?? const []);

  @override
  Future<UserModel> getUser(
    String administratorId,
    String condominiumId,
    String userId,
  ) async => usersByCondo[condominiumId]!.firstWhere((u) => u.id == userId);

  @override
  Future<String> createUser(
    String administratorId,
    String condominiumId,
    UserModel user,
  ) => throw UnimplementedError();

  @override
  Future<void> saveUserWithId(
    String administratorId,
    String condominiumId,
    String userId,
    UserModel user,
  ) async {
    final list = usersByCondo.putIfAbsent(condominiumId, () => []);
    list.add(user.copyWith(id: userId));
  }

  @override
  Future<void> updateUser(
    String administratorId,
    String condominiumId,
    UserModel user,
  ) async {
    final list = usersByCondo[condominiumId];
    if (list == null) return;
    final index = list.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      list[index] = user;
    }
  }

  @override
  Future<void> deleteUser(
    String administratorId,
    String condominiumId,
    String userId,
  ) async {
    usersByCondo[condominiumId]?.removeWhere((u) => u.id == userId);
  }
}

class _InMemoryAccountRoleRepo implements AccountRoleRepository {
  final Map<String, AccountRoleProfile> profilesByUid;

  _InMemoryAccountRoleRepo([Map<String, AccountRoleProfile>? initial])
    : profilesByUid = Map.of(initial ?? const {});

  @override
  Future<AccountRoleProfile?> getAccountRole(String uid) async =>
      profilesByUid[uid];

  @override
  Future<List<AccountRoleProfile>> getAllAccountRoles() async =>
      profilesByUid.values.toList();

  @override
  Future<void> saveAccountRole(
    AccountRoleProfile profile, {
    bool isNew = false,
  }) async {
    profilesByUid[profile.uid] = profile;
  }

  @override
  Future<AccountRoleProfile> resolveOrBootstrapSessionProfile({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    final existing = profilesByUid[uid];
    if (existing != null) return existing;

    final bootstrapped = AccountRoleProfile(
      uid: uid,
      name: displayName ?? email.split('@').first,
      email: email,
      role: UserRole.admin,
      active: true,
    );
    profilesByUid[uid] = bootstrapped;
    return bootstrapped;
  }
}

class _FakeUserAuthProvisioner implements UserAuthProvisioner {
  int _seq = 0;
  final List<String> provisionedEmails = [];
  final List<String> resetEmailsSent = [];

  @override
  Future<T> provisionAndPersist<T>({
    required String name,
    required String email,
    required String temporaryPassword,
    required Future<T> Function(String authUid) persistUser,
  }) async {
    final uid = 'auth-uid-${++_seq}';
    provisionedEmails.add(email);
    return persistUser(uid);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetEmailsSent.add(email);
  }
}

class _FakeFirebaseUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;

  _FakeFirebaseUser({
    required this.uid,
    required this.email,
    this.displayName,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserCredential implements UserCredential {
  @override
  final User? user;

  _FakeUserCredential(this.user);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  final Map<String, _FakeFirebaseUser> registeredUsersByEmail;
  final StreamController<User?> _authController =
      StreamController<User?>.broadcast();
  User? _current;
  int signOutCalls = 0;

  _FakeAuthRepository(this.registeredUsersByEmail);

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> get authStateChanges => _authController.stream;

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final found = registeredUsersByEmail[normalized];
    if (found == null) {
      throw Exception('invalid-credential');
    }
    _current = found;
    _authController.add(_current);
    return _FakeUserCredential(found);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _current = null;
    _authController.add(null);
  }

  void dispose() {
    _authController.close();
  }
}

GoRouter _buildUsersRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.condominiumUsers,
        builder: (context, state) => Scaffold(
          body: CondominiumUsersPage(
            condominiumId: state.pathParameters['condominiumId']!,
            administratorId: state.uri.queryParameters['administratorId'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.newCondominiumUser,
        builder: (context, state) => Scaffold(
          body: NewCondominiumUserPage(
            condominiumId: state.pathParameters['condominiumId']!,
            administratorId: state.uri.queryParameters['administratorId'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.accounts,
        builder: (context, state) => const Scaffold(body: AccountsPage()),
      ),
    ],
  );
}

void main() {
  test(
    'generateTemporaryPassword gera senha forte e UserModel serializa role/isAdmin sem expor senha',
    () {
      for (var i = 0; i < 25; i++) {
        final password = generateTemporaryPassword(length: 10);
        expect(password.length, 10);
        expect(validateTemporaryPassword(password), isNull);
        expect(password.contains(RegExp(r'[0O1lI\s]')), isFalse);
        expect(password.contains(RegExp(r'[A-Z]')), isTrue);
        expect(password.contains(RegExp(r'[a-z]')), isTrue);
        expect(password.contains(RegExp(r'[2-9]')), isTrue);
      }

      const commonUser = UserModel(
        id: 'uid-zelador',
        name: 'Zelador 1',
        email: 'zelador1@condo.com',
        active: true,
        mustChangePassword: true,
      );
      final map = commonUser.toMap();
      expect(commonUser.role, UserRole.user);
      expect(commonUser.isAdmin, isFalse);
      expect(map['role'], 'user');
      expect(map['isAdmin'], isFalse);
      expect(map['mustChangePassword'], isTrue);
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('temporaryPassword'), isFalse);
    },
  );

  testWidgets(
    'LoginPage bloqueia conta Comum (zelador1) e faz signOut imediato, permitindo apenas Administrador',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuthRepo = _FakeAuthRepository({
        'zelador1@condo.com': _FakeFirebaseUser(
          uid: 'uid-zelador-1',
          email: 'zelador1@condo.com',
          displayName: 'Zelador 1',
        ),
        'admin@medeja.com': _FakeFirebaseUser(
          uid: 'uid-admin-1',
          email: 'admin@medeja.com',
          displayName: 'Admin MedeJá',
        ),
      });
      addTearDown(fakeAuthRepo.dispose);

      final fakeRoleRepo = _InMemoryAccountRoleRepo({
        'uid-zelador-1': const AccountRoleProfile(
          uid: 'uid-zelador-1',
          name: 'Zelador 1',
          email: 'zelador1@condo.com',
          role: UserRole.user,
          active: true,
          administratorId: 'adm-1',
          condominiumId: 'condo-1',
        ),
        'uid-admin-1': const AccountRoleProfile(
          uid: 'uid-admin-1',
          name: 'Admin MedeJá',
          email: 'admin@medeja.com',
          role: UserRole.admin,
          active: true,
        ),
      });

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            accountRoleRepositoryProvider.overrideWithValue(fakeRoleRepo),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const LoginPage();
              },
            ),
          ),
        ),
      );

      // 1. Tentativa de login com zelador1 (perfil Comum) -> deve bloquear e deslogar
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-mail'),
        'zelador1@condo.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha'),
        'Mj@8kP4xR9',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(fakeAuthRepo.signOutCalls, 1);
      expect(fakeAuthRepo.currentUser, isNull);
      expect(
        capturedRef.read(authControllerProvider).isAuthorizedAdmin,
        isFalse,
      );
      expect(
        find.textContaining('Acesso restrito a administradores'),
        findsOneWidget,
      );

      // 2. Tentativa de login com admin@medeja.com (perfil Admin) -> deve autorizar
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-mail'),
        'admin@medeja.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha'),
        'Admin@2026!',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(
        capturedRef.read(authControllerProvider).isAuthorizedAdmin,
        isTrue,
      );
      expect(
        capturedRef.read(authControllerProvider).currentProfile?.role,
        UserRole.admin,
      );
    },
  );

  testWidgets(
    'NewCondominiumUserPage cria conta Comum por padrão, sincroniza account_roles e alerta ao criar 2ª conta',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final adminRepo = _InMemoryAdminRepo([
        const AdministratorModel(
          id: 'adm-1',
          name: 'Administradora Horizonte',
          email: 'contato@horizonte.com',
          phone: '11999999999',
          active: true,
        ),
      ]);
      final condoRepo = _InMemoryCondoRepo({
        'adm-1': [
          const CondominiumModel(
            id: 'condo-1',
            name: 'Residencial Solar',
            address: 'Av. Brasil, 100',
            active: true,
          ),
        ],
      });
      final userRepo = _InMemoryUserRepo({});
      final roleRepo = _InMemoryAccountRoleRepo();
      final authProvisioner = _FakeUserAuthProvisioner();
      final fakeAuthRepo = _FakeAuthRepository({});
      addTearDown(fakeAuthRepo.dispose);

      final router = _buildUsersRouter(
        AppRoutes.newCondominiumUserPath('condo-1', administratorId: 'adm-1'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            accountRoleRepositoryProvider.overrideWithValue(roleRepo),
            administratorRepositoryProvider.overrideWithValue(adminRepo),
            condominiumRepositoryProvider.overrideWithValue(condoRepo),
            blockRepositoryProvider.overrideWithValue(_EmptyBlockRepo()),
            apartmentRepositoryProvider.overrideWithValue(
              _EmptyApartmentRepo(),
            ),
            userRepositoryProvider.overrideWithValue(userRepo),
            userAuthProvisionerProvider.overrideWithValue(authProvisioner),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.textContaining('ainda não possui conta vinculada'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome completo *'),
        'Roberto Leiturista',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-mail de acesso *'),
        'roberto@solar.com',
      );

      final createBtn = find.ancestor(
        of: find.text('Criar conta'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('Conta criada com sucesso'), findsOneWidget);
      expect(authProvisioner.provisionedEmails, ['roberto@solar.com']);

      final savedUsers = userRepo.usersByCondo['condo-1']!;
      expect(savedUsers.length, 1);
      expect(savedUsers.first.id, 'auth-uid-1');
      expect(savedUsers.first.role, UserRole.user);
      expect(savedUsers.first.isAdmin, isFalse);
      expect(savedUsers.first.mustChangePassword, isTrue);

      // Também gravou em account_roles com role == UserRole.user (isAdmin == false)
      final syncedRole = roleRepo.profilesByUid['auth-uid-1']!;
      expect(syncedRole.role, UserRole.user);
      expect(syncedRole.isAdmin, isFalse);
      expect(syncedRole.condominiumId, 'condo-1');

      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();

      expect(find.text('Roberto Leiturista'), findsOneWidget);
      expect(find.text('Comum'), findsWidgets);
      expect(find.text('1º acesso pendente'), findsWidgets);

      final newAccountBtn = find.ancestor(
        of: find.text('Nova conta'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      await tester.tap(newAccountBtn);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('já possui 1 conta vinculada'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AccountsPage lista Admins Globais e contas Comuns, destaca condomínios sem conta e envia redefinição de senha',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final adminRepo = _InMemoryAdminRepo([
        const AdministratorModel(
          id: 'adm-1',
          name: 'Administradora Horizonte',
          email: 'contato@horizonte.com',
          phone: '11999999999',
          active: true,
        ),
      ]);
      final condoRepo = _InMemoryCondoRepo({
        'adm-1': [
          const CondominiumModel(
            id: 'condo-1',
            name: 'Residencial Solar',
            address: 'Av. Brasil, 100',
            active: true,
          ),
          const CondominiumModel(
            id: 'condo-2',
            name: 'Condomínio Parque Verde',
            address: 'Rua das Flores, 50',
            active: true,
          ),
        ],
      });
      final userRepo = _InMemoryUserRepo({
        'condo-1': [
          const UserModel(
            id: 'auth-uid-1',
            name: 'Marina Operadora',
            email: 'marina@solar.com',
            active: true,
            role: UserRole.user,
            mustChangePassword: true,
          ),
        ],
      });
      final roleRepo = _InMemoryAccountRoleRepo({
        'uid-global-admin': const AccountRoleProfile(
          uid: 'uid-global-admin',
          name: 'Gabriel Admin',
          email: 'gabriel@medeja.com',
          role: UserRole.admin,
          active: true,
        ),
      });
      final authProvisioner = _FakeUserAuthProvisioner();
      final fakeAuthRepo = _FakeAuthRepository({});
      addTearDown(fakeAuthRepo.dispose);

      final router = _buildUsersRouter(AppRoutes.accounts);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            accountRoleRepositoryProvider.overrideWithValue(roleRepo),
            administratorRepositoryProvider.overrideWithValue(adminRepo),
            condominiumRepositoryProvider.overrideWithValue(condoRepo),
            blockRepositoryProvider.overrideWithValue(_EmptyBlockRepo()),
            apartmentRepositoryProvider.overrideWithValue(
              _EmptyApartmentRepo(),
            ),
            userRepositoryProvider.overrideWithValue(userRepo),
            userAuthProvisionerProvider.overrideWithValue(authProvisioner),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Condomínios aguardando conta inicial (1)'),
        findsOneWidget,
      );
      expect(find.text('Condomínio Parque Verde'), findsOneWidget);
      expect(find.text('Gabriel Admin'), findsOneWidget);
      expect(find.text('Marina Operadora'), findsOneWidget);
      expect(find.text('1 Admin • 1 Comum'), findsOneWidget);

      // Envia redefinição de senha na conta de Marina Operadora (segundo menu de ações)
      await tester.tap(find.byTooltip('Ações da conta').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar redefinição de senha'));
      await tester.pumpAndSettle();

      expect(find.text('Enviar e-mail'), findsOneWidget);
      await tester.tap(find.text('Enviar e-mail'));
      await tester.pumpAndSettle();

      expect(authProvisioner.resetEmailsSent, ['marina@solar.com']);
    },
  );
}
