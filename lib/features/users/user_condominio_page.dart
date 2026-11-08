import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/auth/account_role_datasrc.dart';
import 'package:mede_ja_admin/features/auth/auth_controller.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/condominos/structure_dialogs.dart';
import 'package:mede_ja_admin/features/contas/accounts_controller.dart';
import 'package:mede_ja_admin/features/users/user_credentials_dialog.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';
import 'package:mede_ja_admin/features/users/user_provisioning_datasrc.dart';

class CondominiumUsersPage extends ConsumerStatefulWidget {
  final String condominiumId;
  final String? administratorId;

  const CondominiumUsersPage({
    super.key,
    required this.condominiumId,
    this.administratorId,
  });

  @override
  ConsumerState<CondominiumUsersPage> createState() =>
      _CondominiumUsersPageState();
}

class _CondominiumUsersPageState extends ConsumerState<CondominiumUsersPage> {
  final _searchController = TextEditingController();
  String _search = '';
  String _statusFilter = 'Todos';

  CondominiumScope get _scope => CondominiumScope(
    condominiumId: widget.condominiumId,
    administratorId: widget.administratorId,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final condoState = ref.watch(condominiumDetailsControllerProvider(_scope));
    final currentSessionUid = ref.watch(authControllerProvider).currentProfile?.uid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        if (condoState.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (condoState.error != null && condoState.condominium == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(condoState.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => ref
                              .read(
                                condominiumDetailsControllerProvider(
                                  _scope,
                                ).notifier,
                              )
                              .load(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final normalizedSearch = _search.trim().toLowerCase();
        final filteredUsers = condoState.users.where((user) {
          final matchesSearch =
              normalizedSearch.isEmpty ||
              user.name.toLowerCase().contains(normalizedSearch) ||
              user.email.toLowerCase().contains(normalizedSearch);

          final matchesStatus = switch (_statusFilter) {
            'Ativo' => user.active,
            'Inativo' => !user.active,
            'PrimeiroAcesso' => user.mustChangePassword,
            'Admin' => user.isAdmin,
            'Comum' => !user.isAdmin,
            _ => true,
          };

          return matchesSearch && matchesStatus;
        }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, condoState, isSmall),
              const SizedBox(height: 28),
              _buildSummary(context, condoState),
              if (condoState.users.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildOperationalBanner(context, condoState),
              ],
              const SizedBox(height: 24),
              if (condoState.users.isEmpty)
                _buildEmptyCondominiumAccounts(context, condoState)
              else ...[
                _buildFilters(context, isSmall),
                const SizedBox(height: 16),
                _buildUsersList(
                  context,
                  condoState,
                  filteredUsers,
                  currentSessionUid,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CondominiumDetailsState condoState,
    bool isSmall,
  ) {
    final effectiveAdminId =
        condoState.resolvedAdministratorId ?? widget.administratorId;
    final condoName = condoState.condominium?.name.trim() ?? '';
    final backLabel = condoName.isNotEmpty
        ? 'Voltar para $condoName'
        : 'Voltar para Condomínio';

    final newUserRoute = AppRoutes.newCondominiumUserPath(
      widget.condominiumId,
      administratorId: effectiveAdminId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () {
            context.go(
              AppRoutes.condominiumDetailsPath(
                widget.condominiumId,
                administratorId: effectiveAdminId,
              ),
            );
          },
          icon: const Icon(Icons.arrow_back),
          label: Text(backLabel),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contas e usuários',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (condoName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      condoName,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Atualizar contas',
              onPressed: condoState.isSaving
                  ? null
                  : () => ref
                        .read(
                          condominiumDetailsControllerProvider(_scope).notifier,
                        )
                        .load(),
              icon: const Icon(Icons.refresh),
            ),
            if (!isSmall) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: condoState.isSaving
                    ? null
                    : () => _openLinkExistingAccount(condoState),
                icon: const Icon(Icons.link_outlined),
                label: const Text('Vincular existente'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => context.go(newUserRoute),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Nova conta'),
              ),
            ],
          ],
        ),
        if (isSmall) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: condoState.isSaving
                      ? null
                      : () => _openLinkExistingAccount(condoState),
                  icon: const Icon(Icons.link_outlined),
                  label: const Text('Vincular existente'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go(newUserRoute),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Nova conta'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context,
    CondominiumDetailsState condoState,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns;
        if (constraints.maxWidth >= 1000) {
          columns = 3;
        } else if (constraints.maxWidth >= 650) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 16.0;
        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Total de contas',
                value: '${condoState.totalUsers}',
                subtitle: condoState.totalUsers == 1
                    ? 'Padrão de 1 conta configurada'
                    : '${condoState.inactiveUsers} inativa(s)',
                icon: Icons.people_outline,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Contas ativas',
                value: '${condoState.activeUsers}',
                subtitle: 'Com acesso habilitado',
                icon: Icons.verified_user_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: '1º acesso pendente',
                value: '${condoState.pendingPasswordChangeUsers}',
                subtitle: 'Aguardando troca da senha temporária',
                icon: Icons.password_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOperationalBanner(
    BuildContext context,
    CondominiumDetailsState condoState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSingle = condoState.totalUsers == 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasSingle
            ? colorScheme.secondaryContainer.withValues(alpha: 0.45)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            hasSingle ? Icons.check_circle_outline : Icons.group_outlined,
            size: 20,
            color: hasSingle
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasSingle
                  ? '1 conta vinculada (configuração padrão recomendada por condomínio). Contas com perfil Comum acessam apenas o aplicativo mobile MedeJá.'
                  : 'Este condomínio possui ${condoState.totalUsers} contas vinculadas. Contas com perfil Comum acessam apenas o aplicativo mobile MedeJá.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCondominiumAccounts(
    BuildContext context,
    CondominiumDetailsState condoState,
  ) {
    final effectiveAdminId =
        condoState.resolvedAdministratorId ?? widget.administratorId;
    final newUserRoute = AppRoutes.newCondominiumUserPath(
      widget.condominiumId,
      administratorId: effectiveAdminId,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 52,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma conta vinculada a este condomínio',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Crie a conta operacional do condomínio com uma senha temporária segura para o primeiro acesso no aplicativo MedeJá.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go(newUserRoute),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Criar conta do condomínio'),
                    ),
                    OutlinedButton.icon(
                      onPressed: condoState.isSaving
                          ? null
                          : () => _openLinkExistingAccount(condoState),
                      icon: const Icon(Icons.link_outlined),
                      label: const Text('Vincular conta existente'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, bool isSmall) {
    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Buscar conta',
        hintText: 'Nome ou e-mail',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        suffixIcon: _search.isNotEmpty
            ? IconButton(
                tooltip: 'Limpar busca',
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _search = '';
                  });
                },
                icon: const Icon(Icons.clear),
              )
            : null,
      ),
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
    );

    final statusField = DropdownButtonFormField<String>(
      key: ValueKey(_statusFilter),
      initialValue: _statusFilter,
      decoration: const InputDecoration(
        labelText: 'Filtro / Perfil',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Todos', child: Text('Todas as contas')),
        DropdownMenuItem(value: 'Comum', child: Text('Perfil: Comum (App)')),
        DropdownMenuItem(value: 'Admin', child: Text('Perfil: Admin')),
        DropdownMenuItem(value: 'Ativo', child: Text('Status: Ativas')),
        DropdownMenuItem(value: 'Inativo', child: Text('Status: Inativas')),
        DropdownMenuItem(
          value: 'PrimeiroAcesso',
          child: Text('1º acesso pendente'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _statusFilter = value;
        });
      },
    );

    if (isSmall) {
      return Column(
        children: [searchField, const SizedBox(height: 16), statusField],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 16),
        SizedBox(width: 250, child: statusField),
      ],
    );
  }

  Widget _buildUsersList(
    BuildContext context,
    CondominiumDetailsState condoState,
    List<UserModel> users,
    String? currentSessionUid,
  ) {
    final apartmentsById = <String, ApartmentWithBlockItem>{
      for (final item in condoState.allApartments) item.apartment.id: item,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: users.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Nenhuma conta encontrada para os filtros selecionados.',
                ),
              ),
            )
          : Column(
              children: List.generate(users.length, (index) {
                final user = users[index];
                final linkedApartment = user.apartmentId != null
                    ? apartmentsById[user.apartmentId!]
                    : null;
                final isSelf =
                    currentSessionUid != null && currentSessionUid == user.id;

                return Column(
                  children: [
                    _CondominiumUserTile(
                      user: user,
                      linkedApartment: linkedApartment,
                      isSelfAccount: isSelf,
                      disabled: condoState.isSaving,
                      onCopyEmail: () => _copyEmail(user.email),
                      onEdit: () => _openEditUser(condoState, user, isSelf),
                      onSendPasswordReset: () => _handlePasswordReset(user),
                      onToggleActive: () => _handleToggleUser(user),
                      onViewCredentials: () =>
                          _handleViewCredentials(user, condoState),
                      onRegeneratePassword: () =>
                          _handleRegeneratePassword(user, condoState),
                      onUnlinkCondominium: () =>
                          _handleUnlinkUser(user, condoState),
                      onDeleteUser:
                          isSelf ? null : () => _handleDeleteUser(user),
                    ),
                    if (index < users.length - 1) const Divider(height: 1),
                  ],
                );
              }),
            ),
    );
  }

  Future<void> _copyEmail(String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('E-mail "$email" copiado.')),
    );
  }

  Future<void> _openEditUser(
    CondominiumDetailsState condoState,
    UserModel user,
    bool isSelfAccount,
  ) async {
    await showEditUserDialog(
      context: context,
      user: user,
      isCurrentSessionUser: isSelfAccount,
      availableApartments: condoState.allApartments,
      onSubmit:
          ({
            required String name,
            required UserRole role,
            String? apartmentId,
            bool clearApartmentId = false,
          }) async {
            final controller = ref.read(
              condominiumDetailsControllerProvider(_scope).notifier,
            );
            final ok = await controller.updateCondominiumUser(
              user: user,
              name: name,
              role: role,
              apartmentId: apartmentId,
              clearApartmentId: clearApartmentId,
            );
            if (!mounted) return ok;

            if (ok) {
              ref.invalidate(accountsControllerProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dados e permissões atualizados com sucesso.'),
                ),
              );
            } else {
              final err = ref
                  .read(condominiumDetailsControllerProvider(_scope))
                  .actionError;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(err ?? 'Erro ao atualizar dados da conta.'),
                ),
              );
            }
            return ok;
          },
    );
  }

  Future<void> _handlePasswordReset(UserModel user) async {
    final confirmed = await showConfirmPasswordResetDialog(
      context: context,
      user: user,
    );
    if (!confirmed || !mounted) return;

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );
    final ok = await controller.sendUserPasswordReset(user.email);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'E-mail de redefinição de senha enviado para ${user.email}.',
          ),
        ),
      );
    } else {
      final err = ref
          .read(condominiumDetailsControllerProvider(_scope))
          .actionError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Erro ao enviar redefinição de senha.'),
        ),
      );
    }
  }

  Future<void> _handleToggleUser(UserModel user) async {
    final confirmed = await showConfirmStatusToggleDialog(
      context: context,
      entityLabel: 'conta',
      entityName: '${user.name} (${user.email})',
      currentlyActive: user.active,
    );
    if (!confirmed || !mounted) return;

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );
    final ok = await controller.toggleCondominiumUserActive(user);
    if (!mounted) return;

    if (ok) {
      ref.invalidate(accountsControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.active
                ? 'Conta desativada com sucesso.'
                : 'Conta reativada com sucesso.',
          ),
        ),
      );
    } else {
      final err = ref
          .read(condominiumDetailsControllerProvider(_scope))
          .actionError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Erro ao alterar status da conta.')),
      );
    }
  }

  Future<void> _openLinkExistingAccount(
    CondominiumDetailsState condoState,
  ) async {
    final roleRepo = ref.read(accountRoleRepositoryProvider);
    final allRoles = await roleRepo.getAllAccountRoles();
    final currentCondoUsers = condoState.users.map((u) => u.id).toSet();
    final available = allRoles
        .where(
          (p) =>
              !p.isLinkedToCondominium &&
              !currentCondoUsers.contains(p.uid),
        )
        .toList();

    if (!mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não há contas sem condomínio vinculadas disponíveis. Crie uma nova conta para este condomínio.',
          ),
        ),
      );
      return;
    }

    final selected = await showSelectAccountToLinkDialog(
      context: context,
      condominiumName: condoState.condominium?.name ?? 'Condomínio',
      availableAccounts: available,
    );

    if (selected == null || !mounted) return;

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );
    final success = await controller.linkExistingUser(selected);

    if (!mounted) return;
    if (success) {
      ref.invalidate(accountsControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conta "${selected.name}" vinculada com sucesso.'),
        ),
      );
    } else {
      final err = ref
          .read(condominiumDetailsControllerProvider(_scope))
          .actionError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Erro ao vincular conta.')),
      );
    }
  }

  Future<void> _handleViewCredentials(
    UserModel user,
    CondominiumDetailsState condoState,
  ) async {
    if (user.temporaryPassword != null && user.temporaryPassword!.isNotEmpty) {
      await showProvisionedCredentialsDialog(
        context: context,
        credentials: ProvisionedUserCredentials(
          user: user,
          temporaryPassword: user.temporaryPassword!,
          condominiumId: widget.condominiumId,
          condominiumName: condoState.condominium?.name ?? 'Condomínio',
          administratorName: condoState.administrator?.name,
        ),
        customTitle: 'Senha de 1º acesso de ${user.name}',
      );
    } else {
      final shouldRegenerate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Senha de 1º acesso'),
          content: Text(
            'A senha temporária inicial de "${user.name}" não foi salva nesta conta (criada anteriormente).\n\nDeseja regenerar uma nova senha temporária de primeiro acesso agora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Regenerar nova senha'),
            ),
          ],
        ),
      );
      if (shouldRegenerate == true && mounted) {
        await _handleRegeneratePassword(user, condoState);
      }
    }
  }

  Future<void> _handleRegeneratePassword(
    UserModel user,
    CondominiumDetailsState condoState,
  ) async {
    final newPassword = await showRegenerateTemporaryPasswordDialog(
      context: context,
      userName: user.name,
      userEmail: user.email,
    );

    if (newPassword == null || !mounted) return;

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );

    final credentials = await controller.regenerateUserTemporaryPassword(
      user: user,
      newTemporaryPassword: newPassword,
    );

    if (!mounted) return;

    if (credentials != null) {
      ref.invalidate(accountsControllerProvider);
      await showProvisionedCredentialsDialog(
        context: context,
        credentials: credentials,
        customTitle: 'Nova senha temporária de ${user.name}',
      );
    } else {
      final err = ref
          .read(condominiumDetailsControllerProvider(_scope))
          .actionError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Erro ao regenerar senha temporária.')),
      );
    }
  }

  Future<void> _handleUnlinkUser(
    UserModel user,
    CondominiumDetailsState condoState,
  ) async {
    final confirmed = await showConfirmUnlinkAccountDialog(
      context: context,
      userName: user.name,
      condominiumName: condoState.condominium?.name ?? 'Condomínio',
    );

    if (!confirmed || !mounted) return;

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );
    final success = await controller.unlinkCondominiumUser(user);

    if (!mounted) return;
    if (success) {
      ref.invalidate(accountsControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conta de "${user.name}" desvinculada com sucesso.'),
        ),
      );
    } else {
      final err = ref
          .read(condominiumDetailsControllerProvider(_scope))
          .actionError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Erro ao desvincular conta.')),
      );
    }
  }

  Future<void> _handleDeleteUser(UserModel user) async {
    final confirmed = await showConfirmDeleteAccountDialog(
      context: context,
      userName: user.name,
      userEmail: user.email,
    );

    if (!confirmed || !mounted) return;

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );
    final success = await controller.deleteCondominiumUser(user);

    if (!mounted) return;
    if (success) {
      ref.invalidate(accountsControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conta de "${user.name}" excluída com sucesso.'),
        ),
      );
    } else {
      final err = ref
          .read(condominiumDetailsControllerProvider(_scope))
          .actionError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Erro ao excluir conta.')),
      );
    }
  }
}

class _CondominiumUserTile extends StatelessWidget {
  final UserModel user;
  final ApartmentWithBlockItem? linkedApartment;
  final bool isSelfAccount;
  final bool disabled;
  final VoidCallback onCopyEmail;
  final VoidCallback onEdit;
  final VoidCallback onSendPasswordReset;
  final VoidCallback onToggleActive;
  final VoidCallback? onViewCredentials;
  final VoidCallback? onRegeneratePassword;
  final VoidCallback? onUnlinkCondominium;
  final VoidCallback? onDeleteUser;

  const _CondominiumUserTile({
    required this.user,
    required this.linkedApartment,
    required this.isSelfAccount,
    required this.disabled,
    required this.onCopyEmail,
    required this.onEdit,
    required this.onSendPasswordReset,
    required this.onToggleActive,
    this.onViewCredentials,
    this.onRegeneratePassword,
    this.onUnlinkCondominium,
    this.onDeleteUser,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = user.name.trim().isNotEmpty
        ? user.name.trim().substring(0, 1).toUpperCase()
        : '?';

    final scopeLabel = linkedApartment != null
        ? '${linkedApartment!.block.name} • Apto ${linkedApartment!.apartment.name}'
        : 'Acesso geral ao condomínio';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;

          final userDetails = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: user.active
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: user.active
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Copiar e-mail',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          onPressed: onCopyEmail,
                          icon: const Icon(Icons.copy_outlined, size: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scopeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionsAndChips = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                avatar: Icon(
                  user.isAdmin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.smartphone_outlined,
                  size: 16,
                  color: user.isAdmin
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                label: Text(user.role.shortLabel),
                visualDensity: VisualDensity.compact,
                backgroundColor: user.isAdmin
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHigh,
              ),
              if (user.mustChangePassword)
                ActionChip(
                  avatar: Icon(
                    Icons.key_outlined,
                    size: 16,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  label: const Text('1º acesso pendente'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colorScheme.tertiaryContainer,
                  tooltip:
                      'Clique para ver a senha temporária de primeiro acesso',
                  onPressed: disabled ? null : onViewCredentials,
                ),
              Chip(
                label: Text(user.active ? 'Ativa' : 'Inativa'),
                visualDensity: VisualDensity.compact,
                backgroundColor: user.active
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest,
              ),
              PopupMenuButton<String>(
                tooltip: 'Ações da conta',
                enabled: !disabled,
                onSelected: (action) {
                  switch (action) {
                    case 'view_credentials':
                      onViewCredentials?.call();
                      break;
                    case 'regenerate_password':
                      onRegeneratePassword?.call();
                      break;
                    case 'edit':
                      onEdit();
                      break;
                    case 'unlink_condo':
                      onUnlinkCondominium?.call();
                      break;
                    case 'reset_password':
                      onSendPasswordReset();
                      break;
                    case 'toggle_active':
                      onToggleActive();
                      break;
                    case 'delete_user':
                      onDeleteUser?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (user.mustChangePassword) ...[
                    const PopupMenuItem(
                      value: 'view_credentials',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.key_outlined),
                        title: Text('Ver senha de 1º acesso'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'regenerate_password',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.password_outlined),
                        title: Text('Regenerar senha temporária'),
                      ),
                    ),
                    const PopupMenuDivider(),
                  ],
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar dados e perfil'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'unlink_condo',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.link_off_outlined),
                      title: Text('Desvincular do condomínio'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset_password',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_reset_outlined),
                      title: Text('Enviar redefinição de senha'),
                    ),
                  ),
                  if (!isSelfAccount) ...[
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          user.active
                              ? Icons.person_off_outlined
                              : Icons.person_outline,
                        ),
                        title: Text(
                          user.active ? 'Desativar conta' : 'Reativar conta',
                        ),
                      ),
                    ),
                    if (onDeleteUser != null) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete_user',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.delete_outline,
                            color: colorScheme.error,
                          ),
                          title: Text(
                            'Excluir conta',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                userDetails,
                const SizedBox(height: 12),
                actionsAndChips,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: userDetails),
              const SizedBox(width: 16),
              actionsAndChips,
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 32, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
