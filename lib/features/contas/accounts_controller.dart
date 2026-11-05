import 'package:flutter_riverpod/legacy.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_repo.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/dashboard/dashboard_controller.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';
import 'package:mede_ja_admin/features/users/user_provisioning_datasrc.dart';
import 'package:mede_ja_admin/features/users/user_repo.dart';

final accountsControllerProvider =
    StateNotifierProvider.autoDispose<AccountsController, AccountsState>((ref) {
      final controller = AccountsController(
        adminRepository: ref.watch(administratorRepositoryProvider),
        condominiumRepository: ref.watch(condominiumRepositoryProvider),
        userRepository: ref.watch(userRepositoryProvider),
        userAuthProvisioner: ref.watch(userAuthProvisionerProvider),
        onCachesInvalidated: (adminId, condoId) {
          if (adminId.isNotEmpty) {
            ref.invalidate(adminDetailsControllerProvider(adminId));
          }
          if (condoId.isNotEmpty) {
            ref.invalidate(
              condominiumDetailsControllerProvider(
                CondominiumScope(
                  condominiumId: condoId,
                  administratorId: adminId,
                ),
              ),
            );
            ref.invalidate(
              condominiumDetailsControllerProvider(
                CondominiumScope(condominiumId: condoId),
              ),
            );
          }
          ref.invalidate(dashboardControllerProvider);
        },
      );
      controller.load();
      return controller;
    });

class CondominiumAccountGroup {
  final AdministratorModel administrator;
  final CondominiumModel condominium;
  final List<UserModel> users;

  const CondominiumAccountGroup({
    required this.administrator,
    required this.condominium,
    required this.users,
  });

  int get totalUsers => users.length;

  int get activeUsers => users.where((u) => u.active).length;

  bool get hasAccount => users.isNotEmpty;

  CondominiumAccountGroup copyWith({
    AdministratorModel? administrator,
    CondominiumModel? condominium,
    List<UserModel>? users,
  }) {
    return CondominiumAccountGroup(
      administrator: administrator ?? this.administrator,
      condominium: condominium ?? this.condominium,
      users: users ?? this.users,
    );
  }
}

class AccountOverviewItem {
  final UserModel user;
  final AdministratorModel administrator;
  final CondominiumModel condominium;
  final int condominiumTotalAccounts;

  const AccountOverviewItem({
    required this.user,
    required this.administrator,
    required this.condominium,
    required this.condominiumTotalAccounts,
  });
}

class AccountsState {
  final bool isLoading;
  final bool isSaving;
  final List<AdministratorModel> administrators;
  final List<CondominiumAccountGroup> condominiumGroups;
  final String? error;
  final String? actionError;

  const AccountsState({
    this.isLoading = true,
    this.isSaving = false,
    this.administrators = const [],
    this.condominiumGroups = const [],
    this.error,
    this.actionError,
  });

  List<AccountOverviewItem> get allAccounts {
    final items = <AccountOverviewItem>[];
    for (final group in condominiumGroups) {
      for (final user in group.users) {
        items.add(
          AccountOverviewItem(
            user: user,
            administrator: group.administrator,
            condominium: group.condominium,
            condominiumTotalAccounts: group.totalUsers,
          ),
        );
      }
    }
    items.sort((a, b) {
      final condoCmp = a.condominium.name.toLowerCase().compareTo(
        b.condominium.name.toLowerCase(),
      );
      if (condoCmp != 0) return condoCmp;
      return a.user.name.toLowerCase().compareTo(b.user.name.toLowerCase());
    });
    return items;
  }

  int get totalAccounts =>
      condominiumGroups.fold(0, (sum, group) => sum + group.totalUsers);

  int get activeAccounts =>
      condominiumGroups.fold(0, (sum, group) => sum + group.activeUsers);

  int get inactiveAccounts => totalAccounts - activeAccounts;

  int get pendingPasswordChangeAccounts => condominiumGroups.fold(
    0,
    (sum, group) =>
        sum + group.users.where((u) => u.mustChangePassword).length,
  );

  List<CondominiumAccountGroup> get condominiumsWithoutAccount =>
      condominiumGroups.where((group) => !group.hasAccount).toList();

  CondominiumAccountGroup? findGroup(
    String administratorId,
    String condominiumId,
  ) {
    for (final group in condominiumGroups) {
      if (group.administrator.id == administratorId &&
          group.condominium.id == condominiumId) {
        return group;
      }
    }
    return null;
  }

  List<CondominiumAccountGroup> groupsByAdministrator(String administratorId) {
    return condominiumGroups
        .where((g) => g.administrator.id == administratorId)
        .toList();
  }

  AccountsState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<AdministratorModel>? administrators,
    List<CondominiumAccountGroup>? condominiumGroups,
    String? error,
    bool clearError = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return AccountsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      administrators: administrators ?? this.administrators,
      condominiumGroups: condominiumGroups ?? this.condominiumGroups,
      error: clearError ? null : (error ?? this.error),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}

class AccountsController extends StateNotifier<AccountsState> {
  final AdministratorRepository _adminRepository;
  final CondominiumRepository _condominiumRepository;
  final UserRepository _userRepository;
  final UserAuthProvisioner _userAuthProvisioner;
  final void Function(String administratorId, String condominiumId)?
  _onCachesInvalidated;

  AccountsController({
    required AdministratorRepository adminRepository,
    required CondominiumRepository condominiumRepository,
    required UserRepository userRepository,
    UserAuthProvisioner? userAuthProvisioner,
    void Function(String administratorId, String condominiumId)?
    onCachesInvalidated,
  }) : _adminRepository = adminRepository,
       _condominiumRepository = condominiumRepository,
       _userRepository = userRepository,
       _userAuthProvisioner =
           userAuthProvisioner ?? FirebaseUserAuthProvisioner(),
       _onCachesInvalidated = onCachesInvalidated,
       super(const AccountsState());

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearActionError: true,
    );

    try {
      final rawAdmins = await _adminRepository.getAdministrators();
      final sortedAdmins = List<AdministratorModel>.of(rawAdmins)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final nestedGroups = await Future.wait(
        sortedAdmins.map((admin) async {
          final condos = await _condominiumRepository
              .getCondominiumsByAdministrator(admin.id);
          final sortedCondos = List<CondominiumModel>.of(condos)
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

          return Future.wait(
            sortedCondos.map((condo) async {
              final rawUsers = await _userRepository.getUsers(
                admin.id,
                condo.id,
              );
              final sortedUsers = List<UserModel>.of(rawUsers)
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
              return CondominiumAccountGroup(
                administrator: admin,
                condominium: condo,
                users: sortedUsers,
              );
            }),
          );
        }),
      );

      final allGroups = nestedGroups.expand((list) => list).toList()
        ..sort(
          (a, b) => a.condominium.name.toLowerCase().compareTo(
            b.condominium.name.toLowerCase(),
          ),
        );

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        administrators: sortedAdmins,
        condominiumGroups: allGroups,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: formatAuthAndFirestoreError(e),
      );
    }
  }

  bool hasAccountWithEmail(String email, {String? ignoreUserId}) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    for (final group in state.condominiumGroups) {
      for (final user in group.users) {
        if (user.id != ignoreUserId &&
            user.email.trim().toLowerCase() == normalized) {
          return true;
        }
      }
    }
    return false;
  }

  Future<ProvisionedUserCredentials?> provisionAccount({
    required String administratorId,
    required String condominiumId,
    required String name,
    required String email,
    required String temporaryPassword,
    bool active = true,
  }) async {
    final group = state.findGroup(administratorId, condominiumId);
    if (group == null) {
      state = state.copyWith(
        actionError: 'Selecione uma administradora e um condomínio válidos.',
      );
      return null;
    }

    final trimmedName = name.trim();
    if (trimmedName.length < 3) {
      state = state.copyWith(
        actionError: 'Informe o nome completo (mínimo de 3 caracteres).',
      );
      return null;
    }

    final normalizedEmail = email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(normalizedEmail)) {
      state = state.copyWith(actionError: 'Informe um e-mail válido.');
      return null;
    }

    if (hasAccountWithEmail(normalizedEmail)) {
      state = state.copyWith(
        actionError:
            'Já existe uma conta vinculada com este e-mail na plataforma.',
      );
      return null;
    }

    final passwordValidation = validateTemporaryPassword(temporaryPassword);
    if (passwordValidation != null) {
      state = state.copyWith(actionError: passwordValidation);
      return null;
    }

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      final persistedUser = await _userAuthProvisioner
          .provisionAndPersist<UserModel>(
            name: trimmedName,
            email: normalizedEmail,
            temporaryPassword: temporaryPassword,
            persistUser: (authUid) async {
              final modelToSave = UserModel(
                id: authUid,
                name: trimmedName,
                email: normalizedEmail,
                active: active,
                mustChangePassword: true,
              );
              await _userRepository.saveUserWithId(
                administratorId,
                condominiumId,
                authUid,
                modelToSave,
              );
              return modelToSave.copyWith(createdAt: DateTime.now());
            },
          );

      final updatedGroups = state.condominiumGroups.map((current) {
        if (current.administrator.id != administratorId ||
            current.condominium.id != condominiumId) {
          return current;
        }
        final updatedUsers = [...current.users, persistedUser]
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return current.copyWith(users: updatedUsers);
      }).toList();

      _onCachesInvalidated?.call(administratorId, condominiumId);

      final credentials = ProvisionedUserCredentials(
        user: persistedUser,
        temporaryPassword: temporaryPassword,
        condominiumId: condominiumId,
        condominiumName: group.condominium.name,
        administratorName: group.administrator.name,
      );

      if (!mounted) return credentials;

      state = state.copyWith(
        isSaving: false,
        condominiumGroups: updatedGroups,
        clearActionError: true,
      );
      return credentials;
    } catch (e) {
      if (!mounted) return null;

      state = state.copyWith(
        isSaving: false,
        actionError: formatAuthAndFirestoreError(e),
      );
      return null;
    }
  }

  Future<bool> updateAccountName({
    required AccountOverviewItem item,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.length < 3) {
      state = state.copyWith(
        actionError: 'Informe um nome válido (mínimo de 3 caracteres).',
      );
      return false;
    }

    final updatedUser = item.user.copyWith(name: trimmedName);
    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _userRepository.updateUser(
        item.administrator.id,
        item.condominium.id,
        updatedUser,
      );

      final updatedGroups = state.condominiumGroups.map((group) {
        if (group.administrator.id != item.administrator.id ||
            group.condominium.id != item.condominium.id) {
          return group;
        }
        final updatedUsers = group.users
            .map((u) => u.id == item.user.id ? updatedUser : u)
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return group.copyWith(users: updatedUsers);
      }).toList();

      _onCachesInvalidated?.call(item.administrator.id, item.condominium.id);

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        condominiumGroups: updatedGroups,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        actionError: formatAuthAndFirestoreError(e),
      );
      return false;
    }
  }

  Future<bool> toggleAccountActive(AccountOverviewItem item) async {
    final updatedUser = item.user.copyWith(active: !item.user.active);
    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _userRepository.updateUser(
        item.administrator.id,
        item.condominium.id,
        updatedUser,
      );

      final updatedGroups = state.condominiumGroups.map((group) {
        if (group.administrator.id != item.administrator.id ||
            group.condominium.id != item.condominium.id) {
          return group;
        }
        final updatedUsers = group.users
            .map((u) => u.id == item.user.id ? updatedUser : u)
            .toList();
        return group.copyWith(users: updatedUsers);
      }).toList();

      _onCachesInvalidated?.call(item.administrator.id, item.condominium.id);

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        condominiumGroups: updatedGroups,
        clearActionError: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        actionError: formatAuthAndFirestoreError(e),
      );
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return false;

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _userAuthProvisioner.sendPasswordResetEmail(normalizedEmail);
      if (!mounted) return true;

      state = state.copyWith(isSaving: false, clearActionError: true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        actionError: formatAuthAndFirestoreError(e),
      );
      return false;
    }
  }
}
