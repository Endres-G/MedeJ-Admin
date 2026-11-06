import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamento_page.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamento_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';
import 'package:mede_ja_admin/features/apartamentos/new_apartamento_page.dart';
import 'package:mede_ja_admin/features/blocos/bloco_detail_page.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_page.dart';
import 'package:mede_ja_admin/features/blocos/bloco_repo.dart';
import 'package:mede_ja_admin/features/blocos/new_bloco_page.dart';
import 'package:mede_ja_admin/features/condominos/condominio_detail_page.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_repo.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';
import 'package:mede_ja_admin/features/users/user_repo.dart';

class _InMemoryAdminRepo implements AdministratorRepository {
  final AdministratorModel admin;

  _InMemoryAdminRepo(this.admin);

  @override
  Future<AdministratorModel> getAdministrator(String id) async => admin;

  @override
  Future<List<AdministratorModel>> getAdministrators({bool includeDeleted = false}) async => [admin];

  @override
  Future<List<AdministratorModel>> getDeletedAdministrators() async => [];

  @override
  Future<void> moveToTrash(String id) async {}

  @override
  Future<void> restoreFromTrash(String id) async {}

  @override
  Future<void> permanentDeleteAdministrator(String id) async {}

  @override
  Future<String> createAdministrator(AdministratorModel administrator) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAdministrator(String id) => throw UnimplementedError();

  @override
  Future<void> updateAdministrator(AdministratorModel administrator) =>
      throw UnimplementedError();
}

class _InMemoryCondoRepo implements CondominiumRepository {
  CondominiumModel condominium;

  _InMemoryCondoRepo(this.condominium);

  @override
  Future<CondominiumModel> getCondominium(
    String administratorId,
    String condominiumId,
  ) async => condominium;

  @override
  Future<List<CondominiumModel>> getCondominiumsByAdministrator(
    String administratorId,
  ) async => [condominium];

  @override
  Future<void> updateCondominium(
    String administratorId,
    CondominiumModel updated,
  ) async {
    condominium = updated;
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
}

class _InMemoryBlockRepo implements BlockRepository {
  final List<BlockModel> blocks;
  int _seq = 100;

  _InMemoryBlockRepo(List<BlockModel> initial) : blocks = List.of(initial);

  @override
  Future<List<BlockModel>> getBlocks(
    String administratorId,
    String condominiumId,
  ) async => List.of(blocks);

  @override
  Future<BlockModel> getBlock(
    String administratorId,
    String condominiumId,
    String blockId,
  ) async => blocks.firstWhere((b) => b.id == blockId);

  @override
  Future<String> createBlock(
    String administratorId,
    String condominiumId,
    BlockModel block,
  ) async {
    final id = 'blk-${++_seq}';
    blocks.add(block.copyWith(id: id));
    return id;
  }

  @override
  Future<List<String>> createBlocksBatch(
    String administratorId,
    String condominiumId,
    List<BlockModel> newBlocks,
  ) async {
    final ids = <String>[];
    for (final block in newBlocks) {
      final id = 'blk-${++_seq}';
      ids.add(id);
      blocks.add(block.copyWith(id: id));
    }
    return ids;
  }

  @override
  Future<void> updateBlock(
    String administratorId,
    String condominiumId,
    BlockModel updated,
  ) async {
    final idx = blocks.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      blocks[idx] = updated;
    }
  }

  @override
  Future<void> deleteBlock(
    String administratorId,
    String condominiumId,
    String blockId,
  ) async {
    blocks.removeWhere((b) => b.id == blockId);
  }
}

class _InMemoryApartmentRepo implements ApartmentRepository {
  final Map<String, List<ApartmentModel>> apartmentsByBlock;
  int _seq = 500;

  _InMemoryApartmentRepo(Map<String, List<ApartmentModel>> initial)
    : apartmentsByBlock = {
        for (final entry in initial.entries) entry.key: List.of(entry.value),
      };

  @override
  Future<List<ApartmentModel>> getApartments(
    String administratorId,
    String condominiumId,
    String blockId,
  ) async => List.of(apartmentsByBlock[blockId] ?? const []);

  @override
  Future<ApartmentModel> getApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    String apartmentId,
  ) async =>
      apartmentsByBlock[blockId]!.firstWhere((a) => a.id == apartmentId);

  @override
  Future<String> createApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    ApartmentModel apartment,
  ) async {
    final id = 'apt-${++_seq}';
    final list = apartmentsByBlock.putIfAbsent(blockId, () => []);
    list.add(apartment.copyWith(id: id));
    return id;
  }

  @override
  Future<List<String>> createApartmentsBatch(
    String administratorId,
    String condominiumId,
    String blockId,
    List<ApartmentModel> apartments,
  ) async {
    final ids = <String>[];
    final list = apartmentsByBlock.putIfAbsent(blockId, () => []);
    for (final apt in apartments) {
      final id = 'apt-${++_seq}';
      ids.add(id);
      list.add(apt.copyWith(id: id));
    }
    return ids;
  }

  @override
  Future<void> updateApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    ApartmentModel updated,
  ) async {
    final list = apartmentsByBlock[blockId];
    if (list == null) return;
    final idx = list.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
    }
  }

  @override
  Future<void> deleteApartment(
    String administratorId,
    String condominiumId,
    String blockId,
    String apartmentId,
  ) async {
    apartmentsByBlock[blockId]?.removeWhere((a) => a.id == apartmentId);
  }
}

class _InMemoryUserRepo implements UserRepository {
  final List<UserModel> users;

  _InMemoryUserRepo(this.users);

  @override
  Future<List<UserModel>> getUsers(
    String administratorId,
    String condominiumId,
  ) async => List.of(users);

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
    users.add(user.copyWith(id: userId));
  }

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

GoRouter _createStructureRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.condominiumDetails,
        builder: (context, state) => Scaffold(
          body: CondominiumDetailsPage(
            condominiumId: state.pathParameters['condominiumId']!,
            administratorId: state.uri.queryParameters['administratorId'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.condominiumBlocks,
        builder: (context, state) => Scaffold(
          body: BlocksPage(
            condominiumId: state.pathParameters['condominiumId']!,
            administratorId: state.uri.queryParameters['administratorId'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.newBlock,
        builder: (context, state) => Scaffold(
          body: NewBlockPage(
            condominiumId: state.pathParameters['condominiumId']!,
            administratorId: state.uri.queryParameters['administratorId'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.blockDetails,
        builder: (context, state) => Scaffold(
          body: BlockDetailsPage(
            condominiumId: state.pathParameters['condominiumId']!,
            blockId: state.pathParameters['blockId']!,
            administratorId: state.uri.queryParameters['administratorId'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.condominiumApartments,
        builder: (context, state) => Scaffold(
          body: ApartmentsPage(
            condominiumId: state.pathParameters['condominiumId']!,
            administratorId: state.uri.queryParameters['administratorId'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.newApartment,
        builder: (context, state) => Scaffold(
          body: NewApartmentPage(
            condominiumId: state.pathParameters['condominiumId']!,
            administratorId: state.uri.queryParameters['administratorId'],
            blockId: state.uri.queryParameters['blockId'],
          ),
        ),
      ),
    ],
  );
}

void main() {
  group('Helpers de estrutura (ordenação e geração em lote)', () {
    test('naturalCompare ordena blocos e apartamentos numericamente', () {
      final list = ['1001', '102', '101', '201', '99'];
      list.sort(naturalCompare);
      expect(list, ['99', '101', '102', '201', '1001']);
    });

    test('generateBulkBlockNames gera sequência por letras e números', () {
      expect(
        generateBulkBlockNames(prefix: 'Bloco', count: 3),
        ['Bloco A', 'Bloco B', 'Bloco C'],
      );
      expect(
        generateBulkBlockNames(
          prefix: 'Torre',
          count: 2,
          sequence: BlockNamingSequence.numbers,
        ),
        ['Torre 1', 'Torre 2'],
      );
    });

    test('generateBulkApartmentNumbers gera numeração por centena corretamente', () {
      final generated = generateBulkApartmentNumbers(
        floors: 3,
        apartmentsPerFloor: 2,
        firstNumber: 101,
        pattern: ApartmentNumberingPattern.hundreds,
      );
      expect(generated, ['101', '102', '201', '202', '301', '302']);
    });
  });

  group('Fluxo real de Detalhes do Condomínio, Blocos e Apartamentos', () {
    testWidgets(
      'CondominiumDetailsPage exibe blocos e apartamentos reais do repositório',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final router = _createStructureRouter(
          AppRoutes.condominiumDetailsPath('cond-1', administratorId: 'adm-1'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              administratorRepositoryProvider.overrideWith(
                (ref) => _InMemoryAdminRepo(
                  const AdministratorModel(
                    id: 'adm-1',
                    name: 'Gestão Prime',
                    email: 'prime@empresa.com',
                    active: true,
                  ),
                ),
              ),
              condominiumRepositoryProvider.overrideWith(
                (ref) => _InMemoryCondoRepo(
                  const CondominiumModel(
                    id: 'cond-1',
                    name: 'Residencial Aurora',
                    address: 'Av. Central, 500 - Centro, Curitiba/PR',
                    active: true,
                  ),
                ),
              ),
              blockRepositoryProvider.overrideWith(
                (ref) => _InMemoryBlockRepo(const [
                  BlockModel(id: 'blk-a', name: 'Bloco A', active: true),
                  BlockModel(id: 'blk-b', name: 'Bloco B', active: true),
                ]),
              ),
              apartmentRepositoryProvider.overrideWith(
                (ref) => _InMemoryApartmentRepo({
                  'blk-a': const [
                    ApartmentModel(id: 'a-101', name: '101', active: true),
                    ApartmentModel(id: 'a-102', name: '102', active: true),
                  ],
                  'blk-b': const [],
                }),
              ),
              userRepositoryProvider.overrideWith(
                (ref) => _InMemoryUserRepo(const [
                  UserModel(
                    id: 'u-1',
                    name: 'Operador Campo',
                    email: 'campo@empresa.com',
                    apartmentId: 'a-101',
                    active: true,
                  ),
                ]),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Voltar para Gestão Prime'), findsOneWidget);
        expect(find.text('Residencial Aurora'), findsOneWidget);
        expect(
          find.text('Av. Central, 500 - Centro, Curitiba/PR'),
          findsOneWidget,
        );
        expect(find.text('Administradora: Gestão Prime'), findsOneWidget);
        expect(find.text('Bloco A'), findsOneWidget);
        expect(find.text('Bloco B'), findsOneWidget);
        expect(find.text('101'), findsOneWidget);
        expect(find.text('102'), findsOneWidget);
        expect(find.text('Operador Campo'), findsOneWidget);
      },
    );

    testWidgets(
      'Permite criar novo bloco e gerar apartamentos em lote atualizando o condomínio',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final blockRepo = _InMemoryBlockRepo(const []);
        final apartmentRepo = _InMemoryApartmentRepo(const {});

        final router = _createStructureRouter(
          AppRoutes.condominiumDetailsPath('cond-1', administratorId: 'adm-1'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              administratorRepositoryProvider.overrideWith(
                (ref) => _InMemoryAdminRepo(
                  const AdministratorModel(
                    id: 'adm-1',
                    name: 'Gestão Prime',
                    email: 'prime@empresa.com',
                    active: true,
                  ),
                ),
              ),
              condominiumRepositoryProvider.overrideWith(
                (ref) => _InMemoryCondoRepo(
                  const CondominiumModel(
                    id: 'cond-1',
                    name: 'Residencial Novo Horizonte',
                    address: 'Rua A, 10 - Centro, São Paulo/SP',
                    active: true,
                  ),
                ),
              ),
              blockRepositoryProvider.overrideWith((ref) => blockRepo),
              apartmentRepositoryProvider.overrideWith((ref) => apartmentRepo),
              userRepositoryProvider.overrideWith(
                (ref) => _InMemoryUserRepo(const []),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Nenhum bloco cadastrado neste condomínio.'),
          findsOneWidget,
        );

        // Clica em Criar primeiro bloco
        await tester.tap(find.text('Criar primeiro bloco'));
        await tester.pumpAndSettle();

        expect(
          find.text('Voltar para Residencial Novo Horizonte'),
          findsOneWidget,
        );

        // Preenche o nome do bloco e avança direto para apartamentos
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome do bloco *'),
          'Torre Norte',
        );
        await tester.pump();

        final createAndNext = find.text('Criar e cadastrar apartamentos');
        await tester.ensureVisible(createAndNext);
        await tester.pumpAndSettle();
        await tester.tap(createAndNext);
        await tester.pumpAndSettle();

        expect(blockRepo.blocks.length, 1);
        expect(blockRepo.blocks.first.name, 'Torre Norte');

        // Seleciona modo Gerar em lote na tela de Novo apartamento
        await tester.tap(find.text('Gerar em lote'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Quantidade de andares *'),
          '2',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Apartamentos por andar *'),
          '3',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Primeiro apartamento *'),
          '101',
        );
        await tester.pumpAndSettle();

        final generateBtnText = find.text('Gerar apartamentos');
        await tester.ensureVisible(generateBtnText);
        await tester.pumpAndSettle();
        await tester.tap(generateBtnText);
        await tester.pumpAndSettle();

        // Retorna ao detalhe do condomínio exibindo Torre Norte e os 6 apartamentos gerados
        expect(find.text('Torre Norte'), findsOneWidget);
        expect(find.text('101'), findsOneWidget);
        expect(find.text('103'), findsOneWidget);
        expect(find.text('201'), findsOneWidget);
        expect(find.text('203'), findsOneWidget);
      },
    );
  });
}
