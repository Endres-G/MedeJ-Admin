import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamento_repo.dart';
import 'package:mede_ja_admin/features/blocos/bloco_repo.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_repo.dart';
import 'package:mede_ja_admin/features/users/user_repo.dart';

final dashboardControllerProvider =
    StateNotifierProvider.autoDispose<DashboardController, DashboardState>((
      ref,
    ) {
      final controller = DashboardController(
        adminRepository: ref.watch(administratorRepositoryProvider),
        condominiumRepository: ref.watch(condominiumRepositoryProvider),
        blockRepository: ref.watch(blockRepositoryProvider),
        apartmentRepository: ref.watch(apartmentRepositoryProvider),
        userRepository: ref.watch(userRepositoryProvider),
      );
      controller.load();
      return controller;
    });

class DashboardCondominiumItem {
  final AdministratorModel administrator;
  final CondominiumModel condominium;
  final int blocksCount;
  final int apartmentsCount;
  final int blocksWithoutApartmentsCount;
  final int usersCount;
  final int activeUsersCount;

  const DashboardCondominiumItem({
    required this.administrator,
    required this.condominium,
    required this.blocksCount,
    required this.apartmentsCount,
    required this.blocksWithoutApartmentsCount,
    required this.usersCount,
    required this.activeUsersCount,
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

class DashboardState {
  final bool isLoading;
  final List<AdministratorModel> administrators;
  final List<DashboardCondominiumItem> condominiums;
  final String? error;

  const DashboardState({
    this.isLoading = true,
    this.administrators = const [],
    this.condominiums = const [],
    this.error,
  });

  int get totalAdministrators => administrators.length;

  int get activeAdministrators => administrators.where((a) => a.active).length;

  int get totalCondominiums => condominiums.length;

  int get activeCondominiums =>
      condominiums.where((c) => c.condominium.active).length;

  int get configuredCondominiums =>
      condominiums.where((c) => c.isConfigurationComplete).length;

  int get pendingConfigurationCondominiums =>
      totalCondominiums - configuredCondominiums;

  int get totalBlocks =>
      condominiums.fold(0, (sum, c) => sum + c.blocksCount);

  int get totalApartments =>
      condominiums.fold(0, (sum, c) => sum + c.apartmentsCount);

  int get totalUsers => condominiums.fold(0, (sum, c) => sum + c.usersCount);

  int get activeUsers =>
      condominiums.fold(0, (sum, c) => sum + c.activeUsersCount);

  DashboardState copyWith({
    bool? isLoading,
    List<AdministratorModel>? administrators,
    List<DashboardCondominiumItem>? condominiums,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      administrators: administrators ?? this.administrators,
      condominiums: condominiums ?? this.condominiums,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final AdministratorRepository _adminRepository;
  final CondominiumRepository _condominiumRepository;
  final BlockRepository _blockRepository;
  final ApartmentRepository _apartmentRepository;
  final UserRepository _userRepository;

  DashboardController({
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
       super(const DashboardState());

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final administrators = await _adminRepository.getAdministrators();
      administrators.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      final itemsPerAdmin = await Future.wait(
        administrators.map(_loadAdministratorCondominiums),
      );

      final allCondominiums = itemsPerAdmin.expand((list) => list).toList()
        ..sort(
          (a, b) => a.condominium.name.toLowerCase().compareTo(
            b.condominium.name.toLowerCase(),
          ),
        );

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        administrators: administrators,
        condominiums: allCondominiums,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(isLoading: false, error: _formatError(e));
    }
  }

  Future<List<DashboardCondominiumItem>> _loadAdministratorCondominiums(
    AdministratorModel administrator,
  ) async {
    final condominiums = await _condominiumRepository
        .getCondominiumsByAdministrator(administrator.id);

    return Future.wait(
      condominiums.map(
        (condominium) => _loadCondominiumMetrics(administrator, condominium),
      ),
    );
  }

  Future<DashboardCondominiumItem> _loadCondominiumMetrics(
    AdministratorModel administrator,
    CondominiumModel condominium,
  ) async {
    final blocksFuture = _blockRepository.getBlocks(
      administrator.id,
      condominium.id,
    );
    final usersFuture = _userRepository.getUsers(
      administrator.id,
      condominium.id,
    );

    final blocks = await blocksFuture;
    final users = await usersFuture;

    final apartmentsPerBlock = await Future.wait(
      blocks.map(
        (block) => _apartmentRepository.getApartments(
          administrator.id,
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

    final activeUsers = users.where((u) => u.active).length;

    return DashboardCondominiumItem(
      administrator: administrator,
      condominium: condominium,
      blocksCount: blocks.length,
      apartmentsCount: totalApartments,
      blocksWithoutApartmentsCount: blocksWithoutApartments,
      usersCount: users.length,
      activeUsersCount: activeUsers,
    );
  }

  String _formatError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permissão negada no Firestore (${error.code}). Verifique as regras de segurança.';
        case 'unavailable':
          return 'Serviço do Firebase indisponível no momento. Verifique sua conexão e tente novamente.';
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
