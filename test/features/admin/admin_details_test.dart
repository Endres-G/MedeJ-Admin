import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_details_page.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamento_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_repo.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_repo.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';
import 'package:mede_ja_admin/features/users/user_repo.dart';

class _FakeAdministratorRepository implements AdministratorRepository {
  AdministratorModel? administrator;
  Object? errorToThrow;
  AdministratorModel? lastUpdated;

  _FakeAdministratorRepository({this.administrator, this.errorToThrow});

  @override
  Future<AdministratorModel> getAdministrator(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    if (administrator == null || administrator!.id != id) {
      throw Exception('Administradora não encontrada.');
    }
    return administrator!;
  }

  @override
  Future<void> updateAdministrator(AdministratorModel updated) async {
    if (errorToThrow != null) throw errorToThrow!;
    administrator = updated;
    lastUpdated = updated;
  }

  @override
  Future<String> createAdministrator(AdministratorModel administrator) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAdministrator(String id) => throw UnimplementedError();

  @override
  Future<List<AdministratorModel>> getAdministrators() =>
      throw UnimplementedError();
}

class _FakeCondominiumRepository implements CondominiumRepository {
  final List<CondominiumModel> condominiums;

  _FakeCondominiumRepository(this.condominiums);

  @override
  Future<List<CondominiumModel>> getCondominiumsByAdministrator(
    String administratorId,
  ) async {
    return List.of(condominiums);
  }

  @override
  Future<String> createCondominium(
    String administratorId,
    CondominiumModel condominium,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteCondominium(
    String administratorId,
    String condominiumId,
  ) => throw UnimplementedError();

  @override
  Future<CondominiumModel> getCondominium(
    String administratorId,
    String condominiumId,
  ) => throw UnimplementedError();

  @override
  Future<void> updateCondominium(
    String administratorId,
    CondominiumModel condominium,
  ) => throw UnimplementedError();
}

class _FakeBlockRepository implements BlockRepository {
  final Map<String, List<BlockModel>> blocksByCondo;

  _FakeBlockRepository(this.blocksByCondo);

  @override
  Future<List<BlockModel>> getBlocks(
    String administratorId,
    String condominiumId,
  ) async {
    return blocksByCondo[condominiumId] ?? const [];
  }

  @override
  Future<String> createBlock(
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

  @override
  Future<BlockModel> getBlock(
    String administratorId,
    String condominiumId,
    String blockId,
  ) => throw UnimplementedError();

  @override
  Future<void> updateBlock(
    String administratorId,
    String condominiumId,
    BlockModel block,
  ) => throw UnimplementedError();
}

class _FakeApartmentRepository implements ApartmentRepository {
  final Map<String, List<ApartmentModel>> apartmentsByBlock;

  _FakeApartmentRepository(this.apartmentsByBlock);

  @override
  Future<List<ApartmentModel>> getApartments(
    String administratorId,
    String condominiumId,
    String blockId,
  ) async {
    return apartmentsByBlock['$condominiumId/$blockId'] ?? const [];
  }

  @override
  Future<String> createApartment(
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

  @override
  Future<ApartmentModel> getApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    String apartmentId,
  ) => throw UnimplementedError();

  @override
  Future<void> updateApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    ApartmentModel apartment,
  ) => throw UnimplementedError();
}

class _FakeUserRepository implements UserRepository {
  final Map<String, List<UserModel>> usersByCondo;

  _FakeUserRepository(this.usersByCondo);

  @override
  Future<List<UserModel>> getUsers(
    String administratorId,
    String condominiumId,
  ) async {
    return usersByCondo[condominiumId] ?? const [];
  }

  @override
  Future<String> createUser(
    String administratorId,
    String condominiumId,
    UserModel user,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteUser(
    String administratorId,
    String condominiumId,
    String userId,
  ) => throw UnimplementedError();

  @override
  Future<UserModel> getUser(
    String administratorId,
    String condominiumId,
    String userId,
  ) => throw UnimplementedError();

  @override
  Future<void> updateUser(
    String administratorId,
    String condominiumId,
    UserModel user,
  ) => throw UnimplementedError();
}

void main() {
  testWidgets(
    'AdminDetailsPage exibe dados reais, métricas agregadas e status de configuração',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final adminRepo = _FakeAdministratorRepository(
        administrator: AdministratorModel(
          id: 'adm-1',
          name: 'Gestão Sul Administradora',
          email: 'contato@gestaosul.com.br',
          phone: '(51) 99999-1234',
          active: true,
          createdAt: DateTime(2026, 3, 15),
        ),
      );

      final condoRepo = _FakeCondominiumRepository(const [
        CondominiumModel(
          id: 'cond-1',
          name: 'Residencial Horizonte',
          address: 'Av. Brasil, 500',
          active: true,
        ),
        CondominiumModel(
          id: 'cond-2',
          name: 'Solar das Palmeiras',
          address: 'Rua Verde, 42',
          active: true,
        ),
      ]);

      final blockRepo = _FakeBlockRepository({
        'cond-1': const [
          BlockModel(id: 'blk-1', name: 'Bloco A', active: true),
        ],
        'cond-2': const [],
      });

      final apartmentRepo = _FakeApartmentRepository({
        'cond-1/blk-1': const [
          ApartmentModel(id: 'apt-101', name: '101', active: true),
          ApartmentModel(id: 'apt-102', name: '102', active: true),
        ],
      });

      final userRepo = _FakeUserRepository({
        'cond-1': const [
          UserModel(
            id: 'usr-1',
            name: 'Leiturista 1',
            email: 'l1@gestaosul.com.br',
            active: true,
          ),
        ],
        'cond-2': const [],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            administratorRepositoryProvider.overrideWith((ref) => adminRepo),
            condominiumRepositoryProvider.overrideWith((ref) => condoRepo),
            blockRepositoryProvider.overrideWith((ref) => blockRepo),
            apartmentRepositoryProvider.overrideWith((ref) => apartmentRepo),
            userRepositoryProvider.overrideWith((ref) => userRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminDetailsPage(administratorId: 'adm-1')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gestão Sul Administradora'), findsOneWidget);
      expect(find.text('contato@gestaosul.com.br'), findsOneWidget);
      expect(find.text('(51) 99999-1234'), findsOneWidget);
      expect(find.text('Desde 15/03/2026'), findsOneWidget);

      expect(find.text('Residencial Horizonte'), findsOneWidget);
      expect(find.text('Solar das Palmeiras'), findsOneWidget);
      expect(find.text('Configuração completa'), findsOneWidget);
      expect(find.text('Configuração incompleta'), findsOneWidget);
      expect(
        find.text('Etapas pendentes: Blocos, Apartamentos, Contas'),
        findsOneWidget,
      );
    },
  );

  testWidgets('AdminDetailsPage exibe estado vazio quando não há condomínios', (
    tester,
  ) async {
    final adminRepo = _FakeAdministratorRepository(
      administrator: const AdministratorModel(
        id: 'adm-empty',
        name: 'Admin Sem Condomínios',
        email: 'vazio@empresa.com',
        active: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          administratorRepositoryProvider.overrideWith((ref) => adminRepo),
          condominiumRepositoryProvider.overrideWith(
            (ref) => _FakeCondominiumRepository(const []),
          ),
          blockRepositoryProvider.overrideWith(
            (ref) => _FakeBlockRepository(const {}),
          ),
          apartmentRepositoryProvider.overrideWith(
            (ref) => _FakeApartmentRepository(const {}),
          ),
          userRepositoryProvider.overrideWith(
            (ref) => _FakeUserRepository(const {}),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminDetailsPage(administratorId: 'adm-empty')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Nenhum condomínio vinculado.'), findsOneWidget);
  });

  testWidgets(
    'AdminDetailsPage exibe estado de erro e permite tentar novamente',
    (tester) async {
      final adminRepo = _FakeAdministratorRepository(
        errorToThrow: Exception('Falha de conexão com o Firestore.'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            administratorRepositoryProvider.overrideWith((ref) => adminRepo),
            condominiumRepositoryProvider.overrideWith(
              (ref) => _FakeCondominiumRepository(const []),
            ),
            blockRepositoryProvider.overrideWith(
              (ref) => _FakeBlockRepository(const {}),
            ),
            apartmentRepositoryProvider.overrideWith(
              (ref) => _FakeApartmentRepository(const {}),
            ),
            userRepositoryProvider.overrideWith(
              (ref) => _FakeUserRepository(const {}),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminDetailsPage(administratorId: 'adm-1')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar os dados'), findsOneWidget);
      expect(find.text('Falha de conexão com o Firestore.'), findsOneWidget);

      adminRepo.errorToThrow = null;
      adminRepo.administrator = const AdministratorModel(
        id: 'adm-1',
        name: 'Recuperada Ltda',
        email: 'ok@recuperada.com',
        active: true,
      );

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Recuperada Ltda'), findsOneWidget);
    },
  );

  testWidgets(
    'Dialog Editar administradora habilita Salvar apenas quando algum campo é alterado com valor válido',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final adminRepo = _FakeAdministratorRepository(
        administrator: const AdministratorModel(
          id: 'adm-1',
          name: 'Gestão Sul Administradora',
          email: 'contato@gestaosul.com.br',
          phone: '(51) 99999-1234',
          active: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            administratorRepositoryProvider.overrideWith((ref) => adminRepo),
            condominiumRepositoryProvider.overrideWith(
              (ref) => _FakeCondominiumRepository(const []),
            ),
            blockRepositoryProvider.overrideWith(
              (ref) => _FakeBlockRepository(const {}),
            ),
            apartmentRepositoryProvider.overrideWith(
              (ref) => _FakeApartmentRepository(const {}),
            ),
            userRepositoryProvider.overrideWith(
              (ref) => _FakeUserRepository(const {}),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminDetailsPage(administratorId: 'adm-1')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      FilledButton saveButton() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Salvar'),
      );

      // Ao abrir sem alterações, o botão Salvar deve iniciar desabilitado
      expect(saveButton().onPressed, isNull);
      expect(
        find.text('Altere ao menos um campo para habilitar o salvamento.'),
        findsOneWidget,
      );

      final nameField = find.widgetWithText(TextFormField, 'Nome *');

      // Alterando o nome para um valor válido, Salvar é habilitado
      await tester.enterText(nameField, 'Gestão Sul Atualizada');
      await tester.pump();
      expect(saveButton().onPressed, isNotNull);

      // Revertendo para o valor original, Salvar volta a ficar desabilitado
      await tester.enterText(nameField, 'Gestão Sul Administradora');
      await tester.pump();
      expect(saveButton().onPressed, isNull);

      // Esvaziando um campo obrigatório, Salvar permanece desabilitado
      await tester.enterText(nameField, '');
      await tester.pump();
      expect(saveButton().onPressed, isNull);

      // Preenchendo com alteração válida e salvando
      await tester.enterText(nameField, 'Gestão Sul Atualizada');
      await tester.pump();
      expect(saveButton().onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pumpAndSettle();

      expect(adminRepo.lastUpdated?.name, 'Gestão Sul Atualizada');
      expect(find.text('Gestão Sul Atualizada'), findsOneWidget);
    },
  );
}
