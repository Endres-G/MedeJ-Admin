import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamento_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_repo.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_repo.dart';
import 'package:mede_ja_admin/features/dashboard/dashboard_page.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';
import 'package:mede_ja_admin/features/users/user_repo.dart';

class _FakeAdminRepo implements AdministratorRepository {
  List<AdministratorModel> administrators;
  Object? errorToThrow;

  _FakeAdminRepo({this.administrators = const [], this.errorToThrow});

  @override
  Future<List<AdministratorModel>> getAdministrators({bool includeDeleted = false}) async {
    if (errorToThrow != null) throw errorToThrow!;
    return List.of(administrators);
  }

  @override
  Future<List<AdministratorModel>> getDeletedAdministrators() =>
      throw UnimplementedError();

  @override
  Future<void> moveToTrash(String id) => throw UnimplementedError();

  @override
  Future<void> restoreFromTrash(String id) => throw UnimplementedError();

  @override
  Future<void> permanentDeleteAdministrator(String id) =>
      throw UnimplementedError();

  @override
  Future<AdministratorModel> getAdministrator(String id) =>
      throw UnimplementedError();

  @override
  Future<String> createAdministrator(AdministratorModel administrator) =>
      throw UnimplementedError();

  @override
  Future<void> updateAdministrator(AdministratorModel administrator) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAdministrator(String id) => throw UnimplementedError();
}

class _FakeCondoRepo implements CondominiumRepository {
  final Map<String, List<CondominiumModel>> condosByAdmin;

  _FakeCondoRepo(this.condosByAdmin);

  @override
  Future<List<CondominiumModel>> getCondominiumsByAdministrator(
    String administratorId,
  ) async {
    return List.of(condosByAdmin[administratorId] ?? const []);
  }

  @override
  Future<CondominiumModel> getCondominium(
    String administratorId,
    String condominiumId,
  ) => throw UnimplementedError();

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

class _FakeBlockRepo implements BlockRepository {
  final Map<String, List<BlockModel>> blocksByKey;

  _FakeBlockRepo(this.blocksByKey);

  @override
  Future<List<BlockModel>> getBlocks(
    String administratorId,
    String condominiumId,
  ) async {
    return blocksByKey['$administratorId/$condominiumId'] ?? const [];
  }

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

class _FakeApartmentRepo implements ApartmentRepository {
  final Map<String, List<ApartmentModel>> apartmentsByKey;

  _FakeApartmentRepo(this.apartmentsByKey);

  @override
  Future<List<ApartmentModel>> getApartments(
    String administratorId,
    String condominiumId,
    String blockId,
  ) async {
    return apartmentsByKey['$administratorId/$condominiumId/$blockId'] ??
        const [];
  }

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

class _FakeUserRepo implements UserRepository {
  final Map<String, List<UserModel>> usersByKey;

  _FakeUserRepo(this.usersByKey);

  @override
  Future<List<UserModel>> getUsers(
    String administratorId,
    String condominiumId,
  ) async {
    return usersByKey['$administratorId/$condominiumId'] ?? const [];
  }

  @override
  Future<UserModel> getUser(
    String administratorId,
    String condominiumId,
    String userId,
  ) => throw UnimplementedError();

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
  ) => throw UnimplementedError();

  @override
  Future<void> updateUser(
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
}

void main() {
  testWidgets(
    'DashboardPage exibe indicadores reais agregados e status dos condomínios',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final adminRepo = _FakeAdminRepo(
        administrators: const [
          AdministratorModel(
            id: 'adm-1',
            name: 'Alfa Administradora',
            email: 'alfa@empresa.com',
            active: true,
          ),
          AdministratorModel(
            id: 'adm-2',
            name: 'Beta Administradora',
            email: 'beta@empresa.com',
            active: false,
          ),
        ],
      );

      final condoRepo = _FakeCondoRepo({
        'adm-1': const [
          CondominiumModel(
            id: 'cond-1',
            name: 'Condomínio Parque Sul',
            address: 'Av. Sul, 100',
            active: true,
          ),
        ],
        'adm-2': const [
          CondominiumModel(
            id: 'cond-2',
            name: 'Edifício Norte',
            address: 'Rua Norte, 200',
            active: true,
          ),
        ],
      });

      final blockRepo = _FakeBlockRepo({
        'adm-1/cond-1': const [
          BlockModel(id: 'b1', name: 'Bloco A', active: true),
        ],
      });

      final apartmentRepo = _FakeApartmentRepo({
        'adm-1/cond-1/b1': const [
          ApartmentModel(id: 'a1', name: '101', active: true),
          ApartmentModel(id: 'a2', name: '102', active: true),
          ApartmentModel(id: 'a3', name: '103', active: true),
        ],
      });

      final userRepo = _FakeUserRepo({
        'adm-1/cond-1': const [
          UserModel(
            id: 'u1',
            name: 'Operador 1',
            email: 'op1@alfa.com',
            active: true,
          ),
        ],
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
          child: const MaterialApp(home: Scaffold(body: DashboardPage())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 ativa'), findsOneWidget);
      expect(find.text('1 com config. completa'), findsOneWidget);
      expect(find.text('em 1 bloco'), findsOneWidget);
      expect(find.text('1 ativo'), findsOneWidget);

      expect(find.text('Condomínio Parque Sul'), findsOneWidget);
      expect(find.text('Edifício Norte'), findsOneWidget);
      expect(find.text('Configuração completa'), findsOneWidget);
      expect(find.text('Configuração incompleta'), findsOneWidget);
    },
  );

  testWidgets('DashboardPage exibe estado vazio quando não há dados', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          administratorRepositoryProvider.overrideWith(
            (ref) => _FakeAdminRepo(),
          ),
          condominiumRepositoryProvider.overrideWith(
            (ref) => _FakeCondoRepo(const {}),
          ),
          blockRepositoryProvider.overrideWith(
            (ref) => _FakeBlockRepo(const {}),
          ),
          apartmentRepositoryProvider.overrideWith(
            (ref) => _FakeApartmentRepo(const {}),
          ),
          userRepositoryProvider.overrideWith((ref) => _FakeUserRepo(const {})),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardPage())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Nenhuma administradora cadastrada.'), findsOneWidget);
  });

  testWidgets('DashboardPage exibe erro e permite tentar novamente', (
    tester,
  ) async {
    final adminRepo = _FakeAdminRepo(
      errorToThrow: Exception('Falha ao consultar o Firestore.'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          administratorRepositoryProvider.overrideWith((ref) => adminRepo),
          condominiumRepositoryProvider.overrideWith(
            (ref) => _FakeCondoRepo(const {}),
          ),
          blockRepositoryProvider.overrideWith(
            (ref) => _FakeBlockRepo(const {}),
          ),
          apartmentRepositoryProvider.overrideWith(
            (ref) => _FakeApartmentRepo(const {}),
          ),
          userRepositoryProvider.overrideWith((ref) => _FakeUserRepo(const {})),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardPage())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar o Dashboard'), findsOneWidget);
    expect(find.text('Falha ao consultar o Firestore.'), findsOneWidget);

    adminRepo.errorToThrow = null;
    adminRepo.administrators = const [
      AdministratorModel(
        id: 'adm-ok',
        name: 'Admin OK',
        email: 'ok@admin.com',
        active: true,
      ),
    ];

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum condomínio vinculado às administradoras.'),
      findsOneWidget,
    );
  });
}
