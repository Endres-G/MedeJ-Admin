import 'package:flutter_riverpod/legacy.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_repo.dart';
import 'package:mede_ja_admin/features/leituras/reading_datasrc.dart';
import 'package:mede_ja_admin/features/leituras/reading_model.dart';
import 'package:mede_ja_admin/features/leituras/reading_repo.dart';

final readingsControllerProvider =
    StateNotifierProvider.autoDispose<ReadingsController, ReadingsState>((ref) {
  final controller = ReadingsController(
    adminRepository: ref.watch(administratorRepositoryProvider),
    condominiumRepository: ref.watch(condominiumRepositoryProvider),
    readingRepository: ref.watch(readingRepositoryProvider),
  );
  controller.init();
  return controller;
});

class ReadingsState {
  final bool isLoading;
  final bool isLoadingReadings;
  final List<AdministratorModel> administrators;
  final List<CondominiumModel> condominiums;
  final String? selectedAdministratorId;
  final String? selectedCondominiumId;
  final CondominiumReadingsOverview? overview;
  final String? error;

  const ReadingsState({
    this.isLoading = true,
    this.isLoadingReadings = false,
    this.administrators = const [],
    this.condominiums = const [],
    this.selectedAdministratorId,
    this.selectedCondominiumId,
    this.overview,
    this.error,
  });

  AdministratorModel? get selectedAdministrator {
    if (selectedAdministratorId == null) return null;
    try {
      return administrators.firstWhere((a) => a.id == selectedAdministratorId);
    } catch (_) {
      return null;
    }
  }

  CondominiumModel? get selectedCondominium {
    if (selectedCondominiumId == null) return null;
    try {
      return condominiums.firstWhere((c) => c.id == selectedCondominiumId);
    } catch (_) {
      return null;
    }
  }

  ReadingsState copyWith({
    bool? isLoading,
    bool? isLoadingReadings,
    List<AdministratorModel>? administrators,
    List<CondominiumModel>? condominiums,
    String? selectedAdministratorId,
    String? selectedCondominiumId,
    CondominiumReadingsOverview? overview,
    bool clearOverview = false,
    String? error,
    bool clearError = false,
  }) {
    return ReadingsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingReadings: isLoadingReadings ?? this.isLoadingReadings,
      administrators: administrators ?? this.administrators,
      condominiums: condominiums ?? this.condominiums,
      selectedAdministratorId:
          selectedAdministratorId ?? this.selectedAdministratorId,
      selectedCondominiumId:
          selectedCondominiumId ?? this.selectedCondominiumId,
      overview: clearOverview ? null : (overview ?? this.overview),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReadingsController extends StateNotifier<ReadingsState> {
  final AdministratorRepository _adminRepository;
  final CondominiumRepository _condominiumRepository;
  final ReadingRepository _readingRepository;

  ReadingsController({
    required AdministratorRepository adminRepository,
    required CondominiumRepository condominiumRepository,
    required ReadingRepository readingRepository,
  })  : _adminRepository = adminRepository,
        _condominiumRepository = condominiumRepository,
        _readingRepository = readingRepository,
        super(const ReadingsState());

  Future<void> init() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final admins = await _adminRepository.getAdministrators();
      final sortedAdmins = List<AdministratorModel>.of(admins)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (sortedAdmins.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          administrators: const [],
          condominiums: const [],
        );
        return;
      }

      final firstAdmin = sortedAdmins.first;
      final condos = await _condominiumRepository
          .getCondominiumsByAdministrator(firstAdmin.id);
      final sortedCondos = List<CondominiumModel>.of(condos)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      state = state.copyWith(
        isLoading: false,
        administrators: sortedAdmins,
        selectedAdministratorId: firstAdmin.id,
        condominiums: sortedCondos,
        selectedCondominiumId:
            sortedCondos.isNotEmpty ? sortedCondos.first.id : null,
      );

      if (sortedCondos.isNotEmpty) {
        await loadReadings(firstAdmin.id, sortedCondos.first.id);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectAdministrator(String administratorId) async {
    if (state.selectedAdministratorId == administratorId) return;

    state = state.copyWith(
      isLoadingReadings: true,
      selectedAdministratorId: administratorId,
      selectedCondominiumId: null,
      condominiums: const [],
      clearOverview: true,
      clearError: true,
    );

    try {
      final condos = await _condominiumRepository
          .getCondominiumsByAdministrator(administratorId);
      final sortedCondos = List<CondominiumModel>.of(condos)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final firstCondoId =
          sortedCondos.isNotEmpty ? sortedCondos.first.id : null;

      state = state.copyWith(
        isLoadingReadings: false,
        condominiums: sortedCondos,
        selectedCondominiumId: firstCondoId,
      );

      if (firstCondoId != null) {
        await loadReadings(administratorId, firstCondoId);
      }
    } catch (e) {
      state = state.copyWith(isLoadingReadings: false, error: e.toString());
    }
  }

  Future<void> selectCondominium(String condominiumId) async {
    if (state.selectedCondominiumId == condominiumId) return;
    state = state.copyWith(selectedCondominiumId: condominiumId);
    if (state.selectedAdministratorId != null) {
      await loadReadings(state.selectedAdministratorId!, condominiumId);
    }
  }

  Future<void> loadReadings(
    String administratorId,
    String condominiumId,
  ) async {
    state = state.copyWith(isLoadingReadings: true, clearError: true);
    try {
      final admin = state.selectedAdministrator;
      final condo = state.selectedCondominium;

      final overview =
          await _readingRepository.getCondominiumReadingsOverview(
        administratorId: administratorId,
        administratorName: admin?.name ?? 'Administradora',
        condominiumId: condominiumId,
        condominiumName: condo?.name ?? 'Condomínio',
      );

      state = state.copyWith(
        isLoadingReadings: false,
        overview: overview,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingReadings: false,
        error: 'Erro ao carregar leituras: ${e.toString()}',
      );
    }
  }

  Future<List<ReadingModel>> loadApartmentHistory({
    required String blockId,
    required String apartmentId,
  }) async {
    if (state.selectedAdministratorId == null ||
        state.selectedCondominiumId == null) {
      return const [];
    }

    return _readingRepository.getReadingsHistoryForApartment(
      administratorId: state.selectedAdministratorId!,
      condominiumId: state.selectedCondominiumId!,
      blockId: blockId,
      apartmentId: apartmentId,
    );
  }

  Future<void> refresh() async {
    if (state.selectedAdministratorId != null &&
        state.selectedCondominiumId != null) {
      await loadReadings(
        state.selectedAdministratorId!,
        state.selectedCondominiumId!,
      );
    } else {
      await init();
    }
  }
}
