import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/condominos/cep_datasrc.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_repo.dart';
import 'package:mede_ja_admin/features/dashboard/dashboard_controller.dart';

final cepDataSourceProvider = Provider<CepDataSource>((ref) {
  return CepDataSource();
});

final newCondominiumControllerProvider = StateNotifierProvider.autoDispose
    .family<NewCondominiumController, NewCondominiumState, String>((
      ref,
      administratorId,
    ) {
      final controller = NewCondominiumController(
        administratorId: administratorId,
        adminRepository: ref.watch(administratorRepositoryProvider),
        condominiumRepository: ref.watch(condominiumRepositoryProvider),
        cepDataSource: ref.watch(cepDataSourceProvider),
        onCondominiumCreated: () {
          ref.invalidate(adminDetailsControllerProvider(administratorId));
          ref.invalidate(dashboardControllerProvider);
        },
      );
      controller.loadAdministrator();
      return controller;
    });

class NewCondominiumState {
  final bool isLoadingAdmin;
  final AdministratorModel? administrator;
  final String? adminError;

  final bool isLookingUpCep;
  final String? lastLookedUpCep;
  final String? cepMessage;
  final bool isCepSuccess;

  final bool isSaving;
  final String? saveError;

  const NewCondominiumState({
    this.isLoadingAdmin = true,
    this.administrator,
    this.adminError,
    this.isLookingUpCep = false,
    this.lastLookedUpCep,
    this.cepMessage,
    this.isCepSuccess = false,
    this.isSaving = false,
    this.saveError,
  });

  NewCondominiumState copyWith({
    bool? isLoadingAdmin,
    AdministratorModel? administrator,
    String? adminError,
    bool clearAdminError = false,
    bool? isLookingUpCep,
    String? lastLookedUpCep,
    bool clearLastLookedUpCep = false,
    String? cepMessage,
    bool clearCepMessage = false,
    bool? isCepSuccess,
    bool? isSaving,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return NewCondominiumState(
      isLoadingAdmin: isLoadingAdmin ?? this.isLoadingAdmin,
      administrator: administrator ?? this.administrator,
      adminError: clearAdminError ? null : (adminError ?? this.adminError),
      isLookingUpCep: isLookingUpCep ?? this.isLookingUpCep,
      lastLookedUpCep: clearLastLookedUpCep
          ? null
          : (lastLookedUpCep ?? this.lastLookedUpCep),
      cepMessage: clearCepMessage ? null : (cepMessage ?? this.cepMessage),
      isCepSuccess: isCepSuccess ?? this.isCepSuccess,
      isSaving: isSaving ?? this.isSaving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }
}

class NewCondominiumController extends StateNotifier<NewCondominiumState> {
  final String administratorId;
  final AdministratorRepository _adminRepository;
  final CondominiumRepository _condominiumRepository;
  final CepDataSource _cepDataSource;
  final VoidCallback? _onCondominiumCreated;

  int _cepRequestCounter = 0;

  NewCondominiumController({
    required this.administratorId,
    required AdministratorRepository adminRepository,
    required CondominiumRepository condominiumRepository,
    required CepDataSource cepDataSource,
    VoidCallback? onCondominiumCreated,
  }) : _adminRepository = adminRepository,
       _condominiumRepository = condominiumRepository,
       _cepDataSource = cepDataSource,
       _onCondominiumCreated = onCondominiumCreated,
       super(const NewCondominiumState());

  Future<void> loadAdministrator() async {
    if (!mounted) return;

    if (administratorId.trim().isEmpty) {
      state = state.copyWith(
        isLoadingAdmin: false,
        adminError: 'Identificador da administradora não informado.',
      );
      return;
    }

    state = state.copyWith(isLoadingAdmin: true, clearAdminError: true);

    try {
      final admin = await _adminRepository.getAdministrator(administratorId);
      if (!mounted) return;

      state = state.copyWith(
        isLoadingAdmin: false,
        administrator: admin,
        clearAdminError: true,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        isLoadingAdmin: false,
        adminError: _formatError(e),
      );
    }
  }

  void clearCepFeedback() {
    if (!mounted) return;
    _cepRequestCounter++;
    state = state.copyWith(
      isLookingUpCep: false,
      clearLastLookedUpCep: true,
      clearCepMessage: true,
      isCepSuccess: false,
    );
  }

  Future<CepAddressResult?> lookupCep(
    String rawCep, {
    bool force = false,
  }) async {
    final digits = rawCep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      return null;
    }

    if (!force && state.lastLookedUpCep == digits && state.isCepSuccess) {
      return null;
    }

    final requestId = ++_cepRequestCounter;
    state = state.copyWith(
      isLookingUpCep: true,
      clearCepMessage: true,
      isCepSuccess: false,
    );

    try {
      final result = await _cepDataSource.fetchAddressByCep(digits);

      if (!mounted || requestId != _cepRequestCounter) {
        return null;
      }

      if (result == null) {
        state = state.copyWith(
          isLookingUpCep: false,
          lastLookedUpCep: digits,
          isCepSuccess: false,
          cepMessage:
              'CEP não encontrado. Preencha os dados de endereço manualmente.',
        );
        return null;
      }

      final hasStreet = result.street.isNotEmpty;
      state = state.copyWith(
        isLookingUpCep: false,
        lastLookedUpCep: digits,
        isCepSuccess: true,
        cepMessage: hasStreet
            ? 'Endereço localizado pelo CEP. Informe o número do condomínio.'
            : 'Cidade e UF preenchidas pelo CEP geral. Informe o logradouro, bairro e número.',
      );
      return result;
    } on CepLookupException catch (e) {
      if (!mounted || requestId != _cepRequestCounter) {
        return null;
      }

      state = state.copyWith(
        isLookingUpCep: false,
        lastLookedUpCep: digits,
        isCepSuccess: false,
        cepMessage: e.message,
      );
      return null;
    } catch (_) {
      if (!mounted || requestId != _cepRequestCounter) {
        return null;
      }

      state = state.copyWith(
        isLookingUpCep: false,
        lastLookedUpCep: digits,
        isCepSuccess: false,
        cepMessage:
            'Não foi possível consultar o CEP. Preencha o endereço manualmente.',
      );
      return null;
    }
  }

  Future<String?> createCondominium({
    required String name,
    required String address,
    required bool active,
  }) async {
    if (administratorId.trim().isEmpty) {
      state = state.copyWith(
        saveError: 'Administradora inválida para cadastrar o condomínio.',
      );
      return null;
    }

    state = state.copyWith(isSaving: true, clearSaveError: true);

    try {
      final condominium = CondominiumModel(
        id: '',
        name: name.trim(),
        address: address.trim(),
        active: active,
      );

      final createdId = await _condominiumRepository.createCondominium(
        administratorId,
        condominium,
      );

      _onCondominiumCreated?.call();

      if (!mounted) return createdId;

      state = state.copyWith(isSaving: false, clearSaveError: true);
      return createdId;
    } catch (e) {
      if (!mounted) return null;

      state = state.copyWith(isSaving: false, saveError: _formatError(e));
      return null;
    }
  }

  String _formatError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permissão negada no Firestore (${error.code}). Verifique as regras de segurança.';
        case 'unavailable':
          return 'Serviço do Firebase indisponível no momento. Verifique sua conexão e tente novamente.';
        case 'not-found':
          return 'Administradora não encontrada no Firestore.';
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
}
