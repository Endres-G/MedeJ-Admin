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
  Future<List<AdministratorModel>> getAdministrators() async => List.of(admins);

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
  ) async =>
      usersByCondo[condominiumId]!.firstWhere((u) => u.id == userId);

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
    'generateTemporaryPassword gera senha forte sem caracteres ambíguos e UserModel não serializa senha',
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

      const model = UserModel(
        id: 'uid-1',
        name: 'Operador Teste',
        email: 'operador@teste.com',
        active: true,
        mustChangePassword: true,
      );
      final map = model.toMap();
      expect(map['mustChangePassword'], isTrue);
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('temporaryPassword'), isFalse);
    },
  );

  testWidgets(
    'NewCondominiumUserPage cria conta com UID do Auth, exibe credenciais únicas e alerta quando já existe 1 conta',
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
      final authProvisioner = _FakeUserAuthProvisioner();

      final router = _buildUsersRouter(
        AppRoutes.newCondominiumUserPath('condo-1', administratorId: 'adm-1'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      // Condomínio sem conta inicialmente
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

      // Modal de exibição única da senha temporária deve aparecer
      expect(find.text('Conta criada com sucesso'), findsOneWidget);
      expect(authProvisioner.provisionedEmails, ['roberto@solar.com']);

      final savedUsers = userRepo.usersByCondo['condo-1']!;
      expect(savedUsers.length, 1);
      expect(savedUsers.first.id, 'auth-uid-1');
      expect(savedUsers.first.mustChangePassword, isTrue);

      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();

      // Navegou para a listagem de contas do condomínio exibindo o badge de 1º acesso pendente
      expect(find.text('Roberto Leiturista'), findsOneWidget);
      expect(find.text('1º acesso pendente'), findsWidgets);

      // Ao abrir novamente "Nova conta", deve avisar que já existe 1 conta vinculada sem bloquear
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
    'AccountsPage destaca condomínios sem conta e envia redefinição de senha',
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
            mustChangePassword: true,
          ),
        ],
      });
      final authProvisioner = _FakeUserAuthProvisioner();

      final router = _buildUsersRouter(AppRoutes.accounts);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      // Exibe condomínio sem conta pendente e a conta já existente
      expect(
        find.text('Condomínios aguardando conta inicial (1)'),
        findsOneWidget,
      );
      expect(find.text('Condomínio Parque Verde'), findsOneWidget);
      expect(find.text('Marina Operadora'), findsOneWidget);

      // Aciona envio de e-mail de redefinição de senha pelo menu da conta
      await tester.tap(find.byTooltip('Ações da conta'));
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
