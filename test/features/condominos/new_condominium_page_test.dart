import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/condominos/cep_datasrc.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_repo.dart';
import 'package:mede_ja_admin/features/condominos/new_condominium_controller.dart';
import 'package:mede_ja_admin/features/condominos/novo_condominio_page.dart';

class _FakeAdministratorRepository implements AdministratorRepository {
  final AdministratorModel administrator;

  _FakeAdministratorRepository(this.administrator);

  @override
  Future<AdministratorModel> getAdministrator(String id) async {
    if (administrator.id != id) {
      throw Exception('Administradora não encontrada.');
    }
    return administrator;
  }

  @override
  Future<String> createAdministrator(AdministratorModel administrator) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAdministrator(String id) => throw UnimplementedError();

  @override
  Future<List<AdministratorModel>> getAdministrators() =>
      throw UnimplementedError();

  @override
  Future<void> updateAdministrator(AdministratorModel administrator) =>
      throw UnimplementedError();
}

class _FakeCondominiumRepository implements CondominiumRepository {
  String? lastAdministratorId;
  CondominiumModel? lastCreated;
  String nextGeneratedId = 'condo-generated-01';

  @override
  Future<String> createCondominium(
    String administratorId,
    CondominiumModel condominium,
  ) async {
    lastAdministratorId = administratorId;
    lastCreated = condominium;
    return nextGeneratedId;
  }

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
  Future<List<CondominiumModel>> getCondominiumsByAdministrator(
    String administratorId,
  ) async => const [];

  @override
  Future<void> updateCondominium(
    String administratorId,
    CondominiumModel condominium,
  ) => throw UnimplementedError();
}

class _FakeCepDataSource implements CepDataSource {
  final Map<String, CepAddressResult?> responsesByDigits;

  _FakeCepDataSource(this.responsesByDigits);

  @override
  Future<CepAddressResult?> fetchAddressByCep(String rawCep) async {
    final digits = rawCep.replaceAll(RegExp(r'\D'), '');
    if (!responsesByDigits.containsKey(digits)) {
      return null;
    }
    return responsesByDigits[digits];
  }
}

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: AppRoutes.newCondominiumPath('adm-1'),
    routes: [
      GoRoute(
        path: AppRoutes.administratorDetails,
        builder: (context, state) => Scaffold(
          body: Text(
            'AdminDetails:${state.pathParameters['administratorId']}',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.newCondominium,
        builder: (context, state) => Scaffold(
          body: NewCondominiumPage(
            administratorId: state.pathParameters['administratorId']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.condominiumBlocks,
        builder: (context, state) => Scaffold(
          body: Text(
            'Blocks:${state.pathParameters['condominiumId']}:${state.uri.queryParameters['administratorId']}',
          ),
        ),
      ),
    ],
  );
}

void main() {
  group('formatCondominiumAddress & CepDataSource', () {
    test('formata endereço completo com CEP e complemento', () {
      final address = formatCondominiumAddress(
        street: 'Praça da Sé',
        number: '100',
        complement: 'Bloco Norte',
        neighborhood: 'Sé',
        city: 'São Paulo',
        uf: 'sp',
        cep: '01001-000',
      );

      expect(
        address,
        'Praça da Sé, 100 (Bloco Norte) - Sé, São Paulo/SP - CEP 01001-000',
      );
    });

    test('formata endereço manual sem CEP e com S/N', () {
      final address = formatCondominiumAddress(
        street: 'Estrada das Palmeiras',
        number: 'S/N',
        neighborhood: 'Jardim Botânico',
        city: 'Curitiba',
        uf: 'PR',
      );

      expect(address, 'Estrada das Palmeiras, S/N - Jardim Botânico, Curitiba/PR');
    });

    test('CepDataSource interpreta retorno válido e CEP inexistente do ViaCEP', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('01001000')) {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'cep': '01001-000',
                'logradouro': 'Praça da Sé',
                'complemento': 'lado ímpar',
                'bairro': 'Sé',
                'localidade': 'São Paulo',
                'uf': 'SP',
              }),
            ),
            200,
          );
        }

        return http.Response(jsonEncode({'erro': 'true'}), 200);
      });

      final dataSource = CepDataSource(client: mockClient);

      final found = await dataSource.fetchAddressByCep('01001-000');
      expect(found, isNotNull);
      expect(found!.street, 'Praça da Sé');
      expect(found.neighborhood, 'Sé');
      expect(found.city, 'São Paulo');
      expect(found.uf, 'SP');

      final notFound = await dataSource.fetchAddressByCep('99999-999');
      expect(notFound, isNull);
    });
  });

  group('NewCondominiumPage', () {
    testWidgets(
      'preenche endereço automaticamente via CEP opcional e salva no repositório',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final adminRepo = _FakeAdministratorRepository(
          const AdministratorModel(
            id: 'adm-1',
            name: 'Administradora Horizonte',
            email: 'contato@horizonte.com.br',
            active: true,
          ),
        );
        final condoRepo = _FakeCondominiumRepository();
        final cepSource = _FakeCepDataSource({
          '01001000': const CepAddressResult(
            cep: '01001-000',
            street: 'Praça da Sé',
            complement: '',
            neighborhood: 'Sé',
            city: 'São Paulo',
            uf: 'SP',
          ),
        });

        final router = _buildTestRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              administratorRepositoryProvider.overrideWith((ref) => adminRepo),
              condominiumRepositoryProvider.overrideWith((ref) => condoRepo),
              cepDataSourceProvider.overrideWith((ref) => cepSource),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Administradora: Administradora Horizonte'),
          findsOneWidget,
        );

        ButtonStyleButton buttonByLabel(String label) {
          final finder = find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          );
          return tester.widget<ButtonStyleButton>(finder);
        }

        // Inicia desabilitado enquanto os itens obrigatórios não foram preenchidos
        expect(
          buttonByLabel('Salvar e configurar blocos').onPressed,
          isNull,
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome do condomínio *'),
          'Residencial Bela Vista',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'CEP (opcional)'),
          '01001000',
        );
        await tester.pumpAndSettle();

        // Verifica preenchimento automático via CEP (ainda falta o Número)
        expect(find.text('Praça da Sé'), findsOneWidget);
        expect(find.text('Sé'), findsOneWidget);
        expect(find.text('São Paulo'), findsOneWidget);
        expect(
          buttonByLabel('Salvar e configurar blocos').onPressed,
          isNull,
        );

        // Preenche o Número obrigatório e verifica liberação do botão
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Número *'),
          '250',
        );
        await tester.pumpAndSettle();

        expect(
          buttonByLabel('Salvar e configurar blocos').onPressed,
          isNotNull,
        );

        final submitText = find.text('Salvar e configurar blocos');
        await tester.ensureVisible(submitText);
        await tester.pumpAndSettle();
        await tester.tap(submitText);
        await tester.pumpAndSettle();

        expect(condoRepo.lastAdministratorId, 'adm-1');
        expect(condoRepo.lastCreated?.name, 'Residencial Bela Vista');
        expect(
          condoRepo.lastCreated?.address,
          'Praça da Sé, 250 - Sé, São Paulo/SP - CEP 01001-000',
        );
        expect(condoRepo.lastCreated?.active, isTrue);
        expect(find.text('Blocks:condo-generated-01:adm-1'), findsOneWidget);
      },
    );

    testWidgets(
      'permite cadastrar condomínio manualmente sem informar CEP e com opção Sem número (S/N)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final adminRepo = _FakeAdministratorRepository(
          const AdministratorModel(
            id: 'adm-1',
            name: 'Administradora Horizonte',
            email: 'contato@horizonte.com.br',
            active: true,
          ),
        );
        final condoRepo = _FakeCondominiumRepository();
        final cepSource = _FakeCepDataSource(const {});

        final router = _buildTestRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              administratorRepositoryProvider.overrideWith((ref) => adminRepo),
              condominiumRepositoryProvider.overrideWith((ref) => condoRepo),
              cepDataSourceProvider.overrideWith((ref) => cepSource),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome do condomínio *'),
          'Condomínio Solar Sul',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Logradouro (Rua / Avenida) *',
          ),
          'Estrada Geral',
        );
        await tester.tap(find.widgetWithText(FilterChip, 'Sem número (S/N)'));
        await tester.pump();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Bairro *'),
          'Centro',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Cidade *'),
          'Florianópolis',
        );

        final ufDropdown = find.byType(DropdownButtonFormField<String>);
        await tester.ensureVisible(ufDropdown);
        await tester.pumpAndSettle();
        await tester.tap(ufDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('SC').last);
        await tester.pumpAndSettle();

        final saveAndReturnText = find.text('Salvar e voltar');
        await tester.ensureVisible(saveAndReturnText);
        await tester.pumpAndSettle();
        await tester.tap(saveAndReturnText);
        await tester.pumpAndSettle();

        expect(condoRepo.lastAdministratorId, 'adm-1');
        expect(condoRepo.lastCreated?.name, 'Condomínio Solar Sul');
        expect(
          condoRepo.lastCreated?.address,
          'Estrada Geral, S/N - Centro, Florianópolis/SC',
        );
        expect(find.text('AdminDetails:adm-1'), findsOneWidget);
      },
    );
  });
}
