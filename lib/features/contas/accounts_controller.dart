import 'package:flutter_riverpod/legacy.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';
import 'package:mede_ja_admin/features/auth/account_role_datasrc.dart';
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
        accountRoleRepository: ref.watch(accountRoleRepositoryProvider),
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
  final AdministratorModel? administrator;
  final CondominiumModel? condominium;
  final int condominiumTotalAccounts;

  const AccountOverviewItem({
    required this.user,
    this.administrator,
    this.condominium,
    this.condominiumTotalAccounts = 0,
  });

  bool get isPlatformStandaloneAccount =>
      condominium == null || administrator == null;
}

class AccountsState {
  final bool isLoading;
  final bool isSaving;
  final List<AdministratorModel> administrators;
  final List<CondominiumAccountGroup> condominiumGroups;
  final List<AccountRoleProfile> standalonePlatformAccounts;
  final String? error;
  final String? actionError;

  const AccountsState({
    this.isLoading = true,
    this.isSaving = false,
    this.administrators = const [],
    this.condominiumGroups = const [],
    this.standalonePlatformAccounts = const [],
    this.error,
    this.actionError,
  });

  List<AccountOverviewItem> get allAccounts {
    final items = <AccountOverviewItem>[];

    for (final standalone in standalonePlatformAccounts) {
      items.add(
        AccountOverviewItem(
          user: UserModel(
            id: standalone.uid,
            name: standalone.name,
            email: standalone.email,
            active: standalone.active,
            role: standalone.role,
            mustChangePassword: standalone.mustChangePassword,
            temporaryPassword: standalone.temporaryPassword,
            createdAt: standalone.createdAt,
          ),
        ),
      );
    }

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
      // Exibe Administradores globais primeiro, depois agrupa por condomínio e nome.
      if (a.isPlatformStandaloneAccount != b.isPlatformStandaloneAccount) {
        return a.isPlatformStandaloneAccount ? -1 : 1;
      }
      final aCondo = a.condominium?.name.toLowerCase() ?? '';
      final bCondo = b.condominium?.name.toLowerCase() ?? '';
      final condoCmp = aCondo.compareTo(bCondo);
      if (condoCmp != 0) return condoCmp;
      return a.user.name.toLowerCase().compareTo(b.user.name.toLowerCase());
    });
    return items;
  }

  int get totalAccounts =>
      standalonePlatformAccounts.length +
      condominiumGroups.fold(0, (sum, group) => sum + group.totalUsers);

  int get activeAccounts =>
      standalonePlatformAccounts.where((a) => a.active).length +
      condominiumGroups.fold(0, (sum, group) => sum + group.activeUsers);

  int get inactiveAccounts => totalAccounts - activeAccounts;

  int get adminAccountsCount =>
      allAccounts.where((item) => item.user.isAdmin).length;

  int get commonAccountsCount =>
      allAccounts.where((item) => !item.user.isAdmin).length;

  int get pendingPasswordChangeAccounts =>
      allAccounts.where((item) => item.user.mustChangePassword).length;

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
    List<AccountRoleProfile>? standalonePlatformAccounts,
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
      standalonePlatformAccounts:
          standalonePlatformAccounts ?? this.standalonePlatformAccounts,
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
  final AccountRoleRepository? _accountRoleRepository;
  final void Function(String administratorId, String condominiumId)?
  _onCachesInvalidated;

  AccountsController({
    required AdministratorRepository adminRepository,
    required CondominiumRepository condominiumRepository,
    required UserRepository userRepository,
    UserAuthProvisioner? userAuthProvisioner,
    AccountRoleRepository? accountRoleRepository,
    void Function(String administratorId, String condominiumId)?
    onCachesInvalidated,
  }) : _adminRepository = adminRepository,
       _condominiumRepository = condominiumRepository,
       _userRepository = userRepository,
       _userAuthProvisioner =
           userAuthProvisioner ?? FirebaseUserAuthProvisioner(),
       _accountRoleRepository = accountRoleRepository,
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
      final rawAdminsFuture = _adminRepository.getAdministrators();
      final rawRolesFuture = _loadAllAccountRolesSafely();

      final rawAdmins = await rawAdminsFuture;
      final allAccountRoles = await rawRolesFuture;

      final rolesByUid = <String, AccountRoleProfile>{
        for (final profile in allAccountRoles) profile.uid: profile,
      };

      final sortedAdmins = List<AdministratorModel>.of(rawAdmins)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final condoUserUids = <String>{};
      final condoUserEmails = <String>{};

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
              final enrichedUsers = rawUsers.map((u) {
                condoUserUids.add(u.id);
                if (u.email.trim().isNotEmpty) {
                  condoUserEmails.add(u.email.trim().toLowerCase());
                }
                final roleProfile = rolesByUid[u.id];
                var enriched = u;
                if (roleProfile != null) {
                  if (roleProfile.role != u.role) {
                    enriched = enriched.copyWith(role: roleProfile.role);
                  }
                  if (enriched.temporaryPassword == null &&
                      roleProfile.temporaryPassword != null) {
                    enriched = enriched.copyWith(
                      temporaryPassword: roleProfile.temporaryPassword,
                    );
                  }
                }
                return enriched;
              }).toList()
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );

              return CondominiumAccountGroup(
                administrator: admin,
                condominium: condo,
                users: enrichedUsers,
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

      final standaloneAccounts = allAccountRoles
          .where(
            (profile) =>
                !profile.isLinkedToCondominium &&
                !condoUserUids.contains(profile.uid) &&
                !condoUserEmails.contains(profile.email.trim().toLowerCase()),
          )
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        administrators: sortedAdmins,
        condominiumGroups: allGroups,
        standalonePlatformAccounts: standaloneAccounts,
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

  Future<List<AccountRoleProfile>> _loadAllAccountRolesSafely() async {
    final repo = _accountRoleRepository;
    if (repo == null) return const [];
    try {
      return await repo.getAllAccountRoles();
    } catch (_) {
      return const [];
    }
  }

  bool hasAccountWithEmail(String email, {String? ignoreUserId}) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    for (final item in state.allAccounts) {
      if (item.user.id != ignoreUserId &&
          item.user.email.trim().toLowerCase() == normalized) {
        return true;
      }
    }
    return false;
  }

  Future<ProvisionedUserCredentials?> provisionPlatformAdminAccount({
    required String name,
    required String email,
    required String temporaryPassword,
    bool active = true,
  }) async {
    final roleRepo = _accountRoleRepository;
    if (roleRepo == null) {
      state = state.copyWith(
        actionError: 'Repositório de perfis indisponível.',
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
        actionError: 'Já existe uma conta cadastrada com este e-mail.',
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
      final persistedProfile = await _userAuthProvisioner
          .provisionAndPersist<AccountRoleProfile>(
            name: trimmedName,
            email: normalizedEmail,
            temporaryPassword: temporaryPassword,
            persistUser: (authUid) async {
              final profile = AccountRoleProfile(
                uid: authUid,
                name: trimmedName,
                email: normalizedEmail,
                role: UserRole.admin,
                active: active,
                mustChangePassword: true,
                temporaryPassword: temporaryPassword,
                createdAt: DateTime.now(),
              );
              await roleRepo.saveAccountRole(profile, isNew: true);
              return profile;
            },
          );

      final updatedStandalone = [
        ...state.standalonePlatformAccounts,
        persistedProfile,
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final credentials = ProvisionedUserCredentials(
        user: UserModel(
          id: persistedProfile.uid,
          name: persistedProfile.name,
          email: persistedProfile.email,
          active: persistedProfile.active,
          role: UserRole.admin,
          mustChangePassword: true,
          temporaryPassword: temporaryPassword,
          createdAt: persistedProfile.createdAt,
        ),
        temporaryPassword: temporaryPassword,
        condominiumId: '',
        condominiumName: 'Painel Administrativo MedeJá (Global)',
      );

      if (!mounted) return credentials;

      state = state.copyWith(
        isSaving: false,
        standalonePlatformAccounts: updatedStandalone,
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

  Future<ProvisionedUserCredentials?> provisionAccount({
    required String administratorId,
    required String condominiumId,
    required String name,
    required String email,
    required String temporaryPassword,
    UserRole role = UserRole.user,
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
                role: role,
                mustChangePassword: true,
                temporaryPassword: temporaryPassword,
              );
              await _userRepository.saveUserWithId(
                administratorId,
                condominiumId,
                authUid,
                modelToSave,
              );
              await _accountRoleRepository?.saveAccountRole(
                AccountRoleProfile(
                  uid: authUid,
                  name: trimmedName,
                  email: normalizedEmail,
                  role: role,
                  active: active,
                  mustChangePassword: true,
                  temporaryPassword: temporaryPassword,
                  administratorId: administratorId,
                  condominiumId: condominiumId,
                ),
                isNew: true,
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

  Future<bool> updateAccount({
    required AccountOverviewItem item,
    required String name,
    UserRole? role,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.length < 3) {
      state = state.copyWith(
        actionError: 'Informe um nome válido (mínimo de 3 caracteres).',
      );
      return false;
    }

    final effectiveRole = role ?? item.user.role;
    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      if (item.isPlatformStandaloneAccount) {
        final roleRepo = _accountRoleRepository;
        if (roleRepo == null) return false;
        final updatedProfile = AccountRoleProfile(
          uid: item.user.id,
          name: trimmedName,
          email: item.user.email,
          role: effectiveRole,
          active: item.user.active,
          mustChangePassword: item.user.mustChangePassword,
          createdAt: item.user.createdAt,
        );
        await roleRepo.saveAccountRole(updatedProfile);

        final updatedStandalone = state.standalonePlatformAccounts
            .map((p) => p.uid == item.user.id ? updatedProfile : p)
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (!mounted) return true;
        state = state.copyWith(
          isSaving: false,
          standalonePlatformAccounts: updatedStandalone,
          clearActionError: true,
        );
        return true;
      }

      final adminId = item.administrator!.id;
      final condoId = item.condominium!.id;
      final updatedUser = item.user.copyWith(
        name: trimmedName,
        role: effectiveRole,
      );

      await _userRepository.updateUser(adminId, condoId, updatedUser);
      await _accountRoleRepository?.saveAccountRole(
        AccountRoleProfile(
          uid: updatedUser.id,
          name: updatedUser.name,
          email: updatedUser.email,
          role: updatedUser.role,
          active: updatedUser.active,
          mustChangePassword: updatedUser.mustChangePassword,
          administratorId: adminId,
          condominiumId: condoId,
        ),
      );

      final updatedGroups = state.condominiumGroups.map((group) {
        if (group.administrator.id != adminId ||
            group.condominium.id != condoId) {
          return group;
        }
        final updatedUsers = group.users
            .map((u) => u.id == item.user.id ? updatedUser : u)
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return group.copyWith(users: updatedUsers);
      }).toList();

      _onCachesInvalidated?.call(adminId, condoId);

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
    final nextActive = !item.user.active;
    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      if (item.isPlatformStandaloneAccount) {
        final roleRepo = _accountRoleRepository;
        if (roleRepo == null) return false;
        final updatedProfile = AccountRoleProfile(
          uid: item.user.id,
          name: item.user.name,
          email: item.user.email,
          role: item.user.role,
          active: nextActive,
          mustChangePassword: item.user.mustChangePassword,
          createdAt: item.user.createdAt,
        );
        await roleRepo.saveAccountRole(updatedProfile);

        final updatedStandalone = state.standalonePlatformAccounts
            .map((p) => p.uid == item.user.id ? updatedProfile : p)
            .toList();

        if (!mounted) return true;
        state = state.copyWith(
          isSaving: false,
          standalonePlatformAccounts: updatedStandalone,
          clearActionError: true,
        );
        return true;
      }

      final adminId = item.administrator!.id;
      final condoId = item.condominium!.id;
      final updatedUser = item.user.copyWith(active: nextActive);

      await _userRepository.updateUser(adminId, condoId, updatedUser);
      await _accountRoleRepository?.saveAccountRole(
        AccountRoleProfile(
          uid: updatedUser.id,
          name: updatedUser.name,
          email: updatedUser.email,
          role: updatedUser.role,
          active: updatedUser.active,
          mustChangePassword: updatedUser.mustChangePassword,
          administratorId: adminId,
          condominiumId: condoId,
        ),
      );

      final updatedGroups = state.condominiumGroups.map((group) {
        if (group.administrator.id != adminId ||
            group.condominium.id != condoId) {
          return group;
        }
        final updatedUsers = group.users
            .map((u) => u.id == item.user.id ? updatedUser : u)
            .toList();
        return group.copyWith(users: updatedUsers);
      }).toList();

      _onCachesInvalidated?.call(adminId, condoId);

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

  /// Vincula uma conta existente (geralmente sem condomínio ou transferida)
  /// a um condomínio específico.
  Future<bool> linkAccountToCondominium({
    required AccountOverviewItem item,
    required String administratorId,
    required String condominiumId,
  }) async {
    final group = state.findGroup(administratorId, condominiumId);
    if (group == null) {
      state = state.copyWith(
        actionError: 'Condomínio de destino não encontrado.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      final userToSave = item.user.copyWith();
      await _userRepository.saveUserWithId(
        administratorId,
        condominiumId,
        item.user.id,
        userToSave,
      );

      final updatedRoleProfile = AccountRoleProfile(
        uid: item.user.id,
        name: item.user.name,
        email: item.user.email,
        role: item.user.role,
        active: item.user.active,
        mustChangePassword: item.user.mustChangePassword,
        temporaryPassword: item.user.temporaryPassword,
        administratorId: administratorId,
        condominiumId: condominiumId,
        createdAt: item.user.createdAt,
      );
      await _accountRoleRepository?.saveAccountRole(updatedRoleProfile);

      final updatedStandalone = state.standalonePlatformAccounts
          .where((p) => p.uid != item.user.id)
          .toList();

      final updatedGroups = state.condominiumGroups.map((g) {
        if (g.administrator.id == administratorId &&
            g.condominium.id == condominiumId) {
          final users = [
            ...g.users.where((u) => u.id != item.user.id),
            userToSave,
          ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return g.copyWith(users: users);
        }
        if (item.administrator?.id == g.administrator.id &&
            item.condominium?.id == g.condominium.id) {
          final users = g.users.where((u) => u.id != item.user.id).toList();
          return g.copyWith(users: users);
        }
        return g;
      }).toList();

      _onCachesInvalidated?.call(administratorId, condominiumId);
      if (item.administrator != null && item.condominium != null) {
        _onCachesInvalidated?.call(
          item.administrator!.id,
          item.condominium!.id,
        );
      }

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        standalonePlatformAccounts: updatedStandalone,
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

  /// Desvincula a conta do condomínio, tornando-a uma conta sem vínculo (plataforma/livre).
  Future<bool> unlinkAccountFromCondominium(AccountOverviewItem item) async {
    if (item.isPlatformStandaloneAccount) return false;

    final adminId = item.administrator!.id;
    final condoId = item.condominium!.id;

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      await _userRepository.deleteUser(adminId, condoId, item.user.id);
      final unlinkedProfile = AccountRoleProfile(
        uid: item.user.id,
        name: item.user.name,
        email: item.user.email,
        role: item.user.role,
        active: item.user.active,
        mustChangePassword: item.user.mustChangePassword,
        temporaryPassword: item.user.temporaryPassword,
        createdAt: item.user.createdAt,
      );
      await _accountRoleRepository?.unlinkAccountRole(item.user.id);

      final updatedGroups = state.condominiumGroups.map((g) {
        if (g.administrator.id == adminId && g.condominium.id == condoId) {
          final users = g.users.where((u) => u.id != item.user.id).toList();
          return g.copyWith(users: users);
        }
        return g;
      }).toList();

      final updatedStandalone = [
        ...state.standalonePlatformAccounts.where((p) => p.uid != item.user.id),
        unlinkedProfile,
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      _onCachesInvalidated?.call(adminId, condoId);

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        condominiumGroups: updatedGroups,
        standalonePlatformAccounts: updatedStandalone,
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

  /// Regenera a senha temporária para primeiro acesso da conta.
  Future<ProvisionedUserCredentials?> regenerateTemporaryPassword({
    required AccountOverviewItem item,
    required String newTemporaryPassword,
  }) async {
    final validation = validateTemporaryPassword(newTemporaryPassword);
    if (validation != null) {
      state = state.copyWith(actionError: validation);
      return null;
    }

    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      final currentPwd = item.user.temporaryPassword;
      if (currentPwd != null && currentPwd.isNotEmpty) {
        try {
          await _userAuthProvisioner.updateTemporaryPassword(
            email: item.user.email,
            currentPassword: currentPwd,
            newPassword: newTemporaryPassword,
          );
        } catch (_) {}
      }

      final updatedUser = item.user.copyWith(
        mustChangePassword: true,
        temporaryPassword: newTemporaryPassword,
      );

      if (item.isPlatformStandaloneAccount) {
        final updatedProfile = AccountRoleProfile(
          uid: item.user.id,
          name: item.user.name,
          email: item.user.email,
          role: item.user.role,
          active: item.user.active,
          mustChangePassword: true,
          temporaryPassword: newTemporaryPassword,
          createdAt: item.user.createdAt,
        );
        await _accountRoleRepository?.saveAccountRole(updatedProfile);

        final updatedStandalone = state.standalonePlatformAccounts
            .map((p) => p.uid == item.user.id ? updatedProfile : p)
            .toList();

        final credentials = ProvisionedUserCredentials(
          user: updatedUser,
          temporaryPassword: newTemporaryPassword,
          condominiumId: '',
          condominiumName: 'Painel Administrativo MedeJá (Global)',
        );

        if (!mounted) return credentials;

        state = state.copyWith(
          isSaving: false,
          standalonePlatformAccounts: updatedStandalone,
          clearActionError: true,
        );
        return credentials;
      }

      final adminId = item.administrator!.id;
      final condoId = item.condominium!.id;

      await _userRepository.updateUser(adminId, condoId, updatedUser);
      await _accountRoleRepository?.saveAccountRole(
        AccountRoleProfile(
          uid: updatedUser.id,
          name: updatedUser.name,
          email: updatedUser.email,
          role: updatedUser.role,
          active: updatedUser.active,
          mustChangePassword: true,
          temporaryPassword: newTemporaryPassword,
          administratorId: adminId,
          condominiumId: condoId,
          createdAt: updatedUser.createdAt,
        ),
      );

      final updatedGroups = state.condominiumGroups.map((g) {
        if (g.administrator.id == adminId && g.condominium.id == condoId) {
          final users = g.users
              .map((u) => u.id == item.user.id ? updatedUser : u)
              .toList();
          return g.copyWith(users: users);
        }
        return g;
      }).toList();

      _onCachesInvalidated?.call(adminId, condoId);

      final credentials = ProvisionedUserCredentials(
        user: updatedUser,
        temporaryPassword: newTemporaryPassword,
        condominiumId: condoId,
        condominiumName: item.condominium!.name,
        administratorName: item.administrator!.name,
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

  /// Move a conta para a lixeira (Soft Delete) mantendo o registro por 30 dias.
  Future<bool> deleteAccount(AccountOverviewItem item) async {
    state = state.copyWith(isSaving: true, clearActionError: true);

    try {
      if (!item.isPlatformStandaloneAccount) {
        final adminId = item.administrator!.id;
        final condoId = item.condominium!.id;
        await _userRepository.moveToTrash(adminId, condoId, item.user.id);
        _onCachesInvalidated?.call(adminId, condoId);
      }

      await _accountRoleRepository?.saveAccountRole(
        AccountRoleProfile(
          uid: item.user.id,
          name: item.user.name,
          email: item.user.email,
          role: item.user.role,
          active: false,
          mustChangePassword: item.user.mustChangePassword,
          administratorId: item.administrator?.id,
          condominiumId: item.condominium?.id,
          temporaryPassword: item.user.temporaryPassword,
          createdAt: item.user.createdAt,
        ),
      );

      final updatedStandalone = state.standalonePlatformAccounts
          .where((p) => p.uid != item.user.id)
          .toList();

      final updatedGroups = state.condominiumGroups.map((g) {
        final users = g.users.where((u) => u.id != item.user.id).toList();
        return g.copyWith(users: users);
      }).toList();

      if (!mounted) return true;

      state = state.copyWith(
        isSaving: false,
        standalonePlatformAccounts: updatedStandalone,
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
}
