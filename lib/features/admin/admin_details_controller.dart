import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamento_repo.dart';
import 'package:mede_ja_admin/features/blocos/bloco_repo.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_repo.dart';
import 'package:mede_ja_admin/features/users/user_repo.dart';

final administratorRepositoryProvider = Provider<AdministratorRepository>((
  ref,
) {
  return AdministratorRepository();
});

final condominiumRepositoryProvider = Provider<CondominiumRepository>((ref) {
  return CondominiumRepository();
});

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository();
});

final apartmentRepositoryProvider = Provider<ApartmentRepository>((ref) {
  return ApartmentRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final adminDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<AdminDetailsController, AdminDetailsState, String>((
      ref,
      administratorId,
    ) {
      final controller = AdminDetailsController(
        administratorId: administratorId,
        adminRepository: ref.watch(administratorRepositoryProvider),
        condominiumRepository: ref.watch(condominiumRepositoryProvider),
        blockRepository: ref.watch(blockRepositoryProvider),
        apartmentRepository: ref.watch(apartmentRepositoryProvider),
        userRepository: ref.watch(userRepositoryProvider),
      );
      controller.load();
      return controller;
    });

class CondominiumOverviewItem {
  final CondominiumModel condominium;
  final int blocksCount;
  final int apartmentsCount;
  final int blocksWithoutApartmentsCount;
  final int usersCount;

  const CondominiumOverviewItem({
    required this.condominium,
    required this.blocksCount,
    required this.apartmentsCount,
    required this.blocksWithoutApartmentsCount,
    required this.usersCount,
  });

  List<String> get pendingSteps {
    final steps = <String>[];
    if (blocksCount == 0) {
      steps.add('Blocos');
      steps.add('Apartamentos');
    } else if (apartmentsCount == 0 || blocksWithoutApartmentsCount > 0) {
      steps.add('Apartamentos');
    }

    if (usersCount == 0) {
      steps.add('Contas');
    }

    return steps;
  }

  bool get isConfigurationComplete => pendingSteps.isEmpty;

  String get configurationStatusLabel => isConfigurationComplete
      ? 'Configuração completa'
      : 'Configuração incompleta';
}

class AdminDetailsState {
  final bool isLoading;
  final bool isSaving;
  final AdministratorModel? administrator;
  final List<CondominiumOverviewItem> condominiums;
  final String? error;
  final String? actionError;

  const AdminDetailsState({
    this.isLoading = true,
    this.isSaving = false,
    this.administrator,
    this.condominiums = const [],
    this.error,
    this.actionError,
  });

  int get totalCondominiums => condominiums.length;

  int get activeCondominiums =>
      condominiums.where((item) => item.condominium.active).length;

  int get totalBlocks =>
      condominiums.fold(0, (sum, item) => sum + item.blocksCount);

  int get totalApartments =>
      condominiums.fold(0, (sum, item) => sum + item.apartmentsCount);

  int get totalUsers =>
      condominiums.fold(0, (sum, item) => sum + item.usersCount);

  AdminDetailsState copyWith({
    bool? isLoading,
    bool? isSaving,
    AdministratorModel? administrator,
    List<CondominiumOverviewItem>? condominiums,
    String? error,
    bool clearError = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return AdminDetailsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      administrator: administrator ?? this.administrator,
      condominiums: condominiums ?? this.condominiums,
      error: clearError ? null : (error ?? this.error),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}

class AdminDetailsController extends StateNotifier<AdminDetailsState> {
  final String administratorId;
  final AdministratorRepository _adminRepository;
  final CondominiumRepository _condominiumRepository;
  final BlockRepository _blockRepository;
  final ApartmentRepository _apartmentRepository;
  final UserRepository _userRepository;

  AdminDetailsController({
    required this.administratorId,
    required AdministratorRepository adminRepository,
    required CondominiumRepository condominiumRepository,
    required BlockRepository blockRepository,
    required ApartmentRepository apartmentRepository,
    required UserRepository userRepository,
  }) : _adminRepository = adminRepository,
       _condominiumRepository = condominiumRepository,
       _blockRepository = blockRepository,
       _apartmentRepository = apartmentRepository,
       _userRepository = userRepository,
       super(const AdminDetailsState());

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearActionError: true,
    );

    AdministratorModel? loadedAdministrator = state.administrator;

    try {
      loadedAdministrator = await _adminRepository.getAdministrator(
        administratorId,
      );

      final condominiumsList = await _condominiumRepository
          .getCondominiumsByAdministrator(administratorId);

      condominiumsList.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      final overviewItems = await Future.wait(
        condominiumsList.map(_loadCondominiumOverview),
      );

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        administrator: loadedAdministrator,
        condominiums: overviewItems,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        administrator: loadedAdministrator,
        error: _formatError(e),
      );
    }
  }

  Future<CondominiumOverviewItem> _loadCondominiumOverview(
    CondominiumModel condominium,
  ) async {
    final blocksFuture = _blockRepository.getBlocks(
      administratorId,
      condominium.id,
    );
    final usersFuture = _userRepository.getUsers(
      administratorId,
      condominium.id,
    );

    final blocks = await blocksFuture;
    final users = await usersFuture;

    final apartmentsPerBlock = await Future.wait(
      blocks.map(
        (block) => _apartmentRepository.getApartments(
          administratorId,
          condominium.id,
          block.id,
        ),
      ),
    );

    var totalApartments = 0;
    var blocksWithoutApartments = 0;

    for (final apartments in apartmentsPerBlock) {
      totalApartments += apartments.length;
      if (apartments.isEmpty) {
        blocksWithoutApartments++;
      }
    }

    return CondominiumOverviewItem(
      condominium: condominium,
      blocksCount: blocks.length,
      apartmentsCount: totalApartments,
      blocksWithoutApartmentsCount: blocksWithoutApartments,
      usersCount: users.length,
    );
  }

  Future<bool> updateAdministrator({
    required String name,
    required String email,
    String? phone,
  }) async {
    final current = state.administrator;
    if (current == null) return false;

    final normalizedPhone = phone?.trim();
    final updated = current.copyWith(
      name: name.trim(),
      email: email.trim(),
      phone: (normalizedPhone == null || normalizedPhone.isEmpty)
          ? null
          : normalizedPhone,
      clearPhone: normalizedPhone == null || normalizedPhone.isEmpty,
    );

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _adminRepository.updateAdministrator(updated);

      if (!mounted) return false;

      state = state.copyWith(
        isSaving: false,
        administrator: updated,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
    }
  }

  Future<bool> toggleAdministratorActive() async {
    final current = state.administrator;
    if (current == null) return false;

    final updated = current.copyWith(active: !current.active);

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _adminRepository.updateAdministrator(updated);

      if (!mounted) return false;

      state = state.copyWith(
        isSaving: false,
        administrator: updated,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSaving: false, actionError: _formatError(e));
      return false;
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
