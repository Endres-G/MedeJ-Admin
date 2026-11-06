import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/auth/auth_controller.dart';
import 'package:mede_ja_admin/features/condominos/structure_dialogs.dart';
import 'package:mede_ja_admin/features/contas/accounts_controller.dart';
import 'package:mede_ja_admin/features/users/user_credentials_dialog.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';
import 'package:mede_ja_admin/features/users/user_provisioning_datasrc.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  static const String _allAdminsSentinel = '__ALL_ADMINS__';
  static const String _globalOnlySentinel = '__GLOBAL_ONLY__';

  final _searchController = TextEditingController();
  String _search = '';
  String _adminFilter = _allAdminsSentinel;
  String _statusFilter = 'Todos';
  bool _showAllPendingCondos = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsControllerProvider);
    final currentSessionUid = ref
        .watch(authControllerProvider)
        .currentProfile
        ?.uid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 750;

        if (state.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.error != null &&
            state.condominiumGroups.isEmpty &&
            state.standalonePlatformAccounts.isEmpty) {
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
                        Text(state.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => ref
                              .read(accountsControllerProvider.notifier)
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

        final validAdminIds = state.administrators.map((a) => a.id).toSet();
        final effectiveAdminFilter =
            (_adminFilter == _globalOnlySentinel ||
                (_adminFilter != _allAdminsSentinel &&
                    validAdminIds.contains(_adminFilter)))
            ? _adminFilter
            : _allAdminsSentinel;

        final query = _search.trim().toLowerCase();
        final filteredAccounts = state.allAccounts.where((item) {
          if (effectiveAdminFilter == _globalOnlySentinel) {
            if (!item.isPlatformStandaloneAccount) return false;
          } else if (effectiveAdminFilter != _allAdminsSentinel) {
            if (item.administrator?.id != effectiveAdminFilter) return false;
          }

          final matchesStatus = switch (_statusFilter) {
            'Admin' => item.user.isAdmin,
            'Comum' => !item.user.isAdmin,
            'Ativo' => item.user.active,
            'Inativo' => !item.user.active,
            'PrimeiroAcesso' => item.user.mustChangePassword,
            _ => true,
          };
          if (!matchesStatus) return false;

          if (query.isEmpty) return true;
          final condoName = item.condominium?.name.toLowerCase() ?? '';
          final adminName = item.administrator?.name.toLowerCase() ?? '';
          return item.user.name.toLowerCase().contains(query) ||
              item.user.email.toLowerCase().contains(query) ||
              item.user.role.label.toLowerCase().contains(query) ||
              condoName.contains(query) ||
              adminName.contains(query);
        }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state, isSmall),
              const SizedBox(height: 24),
              _buildSummary(context, state),
              if (state.condominiumsWithoutAccount.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildCondominiumsWithoutAccountSection(context, state),
              ],
              const SizedBox(height: 28),
              _buildSectionTitle(context, state),
              const SizedBox(height: 16),
              _buildFilters(context, state, effectiveAdminFilter, isSmall),
              const SizedBox(height: 16),
              _buildAccountsList(
                context,
                state,
                filteredAccounts,
                currentSessionUid,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AccountsState state,
    bool isSmall,
  ) {
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contas e usuários',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Gerencie administradores do painel e contas comuns/operacionais vinculadas aos condomínios.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );

    final createButton = FilledButton.icon(
      onPressed: state.isSaving ? null : () => _openCreateAccountDialog(),
      icon: const Icon(Icons.person_add_outlined),
      label: const Text('Nova conta'),
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleColumn),
              IconButton(
                tooltip: 'Atualizar lista de contas',
                onPressed: state.isSaving
                    ? null
                    : () =>
                          ref.read(accountsControllerProvider.notifier).load(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: createButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleColumn),
        const SizedBox(width: 16),
        IconButton(
          tooltip: 'Atualizar lista de contas',
          onPressed: state.isSaving
              ? null
              : () => ref.read(accountsControllerProvider.notifier).load(),
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 8),
        createButton,
      ],
    );
  }

  Widget _buildSummary(BuildContext context, AccountsState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final int columns;
        if (constraints.maxWidth >= 1100) {
          columns = 4;
        } else if (constraints.maxWidth >= 680) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Total de contas',
                value: '${state.totalAccounts}',
                subtitle:
                    '${state.adminAccountsCount} Admin • ${state.commonAccountsCount} Comum',
                icon: Icons.key_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Contas ativas',
                value: '${state.activeAccounts}',
                subtitle: '${state.inactiveAccounts} inativa(s)',
                icon: Icons.verified_user_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: '1º acesso pendente',
                value: '${state.pendingPasswordChangeAccounts}',
                subtitle: 'Aguardando troca da senha inicial',
                icon: Icons.password_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Condomínios sem conta',
                value: '${state.condominiumsWithoutAccount.length}',
                subtitle: state.condominiumsWithoutAccount.isEmpty
                    ? 'Todos os condomínios vinculados'
                    : 'Pendentes de 1ª conta operacional',
                icon: Icons.apartment_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCondominiumsWithoutAccountSection(
    BuildContext context,
    AccountsState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final pending = state.condominiumsWithoutAccount;
    const previewLimit = 5;
    final visible = _showAllPendingCondos || pending.length <= previewLimit
        ? pending
        : pending.sublist(0, previewLimit);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pending_actions_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Condomínios aguardando conta inicial (${pending.length})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cada condomínio precisa de pelo menos 1 conta operacional (Comum) para execução das leituras no aplicativo MedeJá.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: visible.map((group) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.condominium.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            group.administrator.name,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      FilledButton.tonalIcon(
                        onPressed: state.isSaving
                            ? null
                            : () => _openCreateAccountDialog(
                                initialAdministratorId: group.administrator.id,
                                initialCondominiumId: group.condominium.id,
                                initialRole: UserRole.user,
                              ),
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('Criar conta'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (pending.length > previewLimit) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllPendingCondos = !_showAllPendingCondos;
                  });
                },
                icon: Icon(
                  _showAllPendingCondos
                      ? Icons.expand_less
                      : Icons.expand_more,
                ),
                label: Text(
                  _showAllPendingCondos
                      ? 'Mostrar menos'
                      : 'Ver todos os ${pending.length} condomínios sem conta',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, AccountsState state) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Contas cadastradas',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(
    BuildContext context,
    AccountsState state,
    String effectiveAdminFilter,
    bool isSmall,
  ) {
    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Buscar conta',
        hintText: 'Nome, e-mail, perfil, condomínio ou administradora',
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

    final adminDropdown = DropdownButtonFormField<String>(
      key: ValueKey(effectiveAdminFilter),
      initialValue: effectiveAdminFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Escopo / Administradora',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(
          value: _allAdminsSentinel,
          child: Text('Todos os escopos'),
        ),
        if (state.standalonePlatformAccounts.isNotEmpty)
          const DropdownMenuItem(
            value: _globalOnlySentinel,
            child: Text('Apenas Admins Globais (Painel)'),
          ),
        ...state.administrators.map(
          (admin) => DropdownMenuItem(
            value: admin.id,
            child: Text(admin.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _adminFilter = value;
        });
      },
    );

    final statusDropdown = DropdownButtonFormField<String>(
      key: ValueKey(_statusFilter),
      initialValue: _statusFilter,
      decoration: const InputDecoration(
        labelText: 'Perfil / Status',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Todos', child: Text('Todos')),
        DropdownMenuItem(value: 'Admin', child: Text('Perfil: Admin')),
        DropdownMenuItem(value: 'Comum', child: Text('Perfil: Comum (App)')),
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
        children: [
          searchField,
          const SizedBox(height: 12),
          adminDropdown,
          const SizedBox(height: 12),
          statusDropdown,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: searchField),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: adminDropdown),
        const SizedBox(width: 16),
        SizedBox(width: 230, child: statusDropdown),
      ],
    );
  }

  Widget _buildAccountsList(
    BuildContext context,
    AccountsState state,
    List<AccountOverviewItem> accounts,
    String? currentSessionUid,
  ) {
    if (state.totalAccounts == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma conta cadastrada na plataforma',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Clique em "Nova conta" para criar uma conta operacional de condomínio (Comum) ou um Administrador do painel.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openCreateAccountDialog(),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Criar primeira conta'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (accounts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Nenhuma conta encontrada para os filtros selecionados.',
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(accounts.length, (index) {
          final item = accounts[index];
          final isSelf =
              currentSessionUid != null && currentSessionUid == item.user.id;

          return Column(
            children: [
              _GlobalAccountTile(
                item: item,
                isSelfAccount: isSelf,
                disabled: state.isSaving,
                onCopyEmail: () => _copyEmail(item.user.email),
                onOpenCondominiumUsers: item.isPlatformStandaloneAccount
                    ? null
                    : () => context.go(
                        AppRoutes.condominiumUsersPath(
                          item.condominium!.id,
                          administratorId: item.administrator!.id,
                        ),
                      ),
                onEdit: () => _openEditAccount(item, isSelf),
                onSendPasswordReset: () => _handlePasswordReset(item),
                onToggleActive: () => _handleToggleAccount(item),
              ),
              if (index < accounts.length - 1) const Divider(height: 1),
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

  Future<void> _openCreateAccountDialog({
    String? initialAdministratorId,
    String? initialCondominiumId,
    UserRole? initialRole,
  }) async {
    final credentials = await showDialog<ProvisionedUserCredentials>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateGlobalAccountDialog(
        initialAdministratorId: initialAdministratorId,
        initialCondominiumId: initialCondominiumId,
        initialRole: initialRole,
      ),
    );

    if (credentials == null || !mounted) return;

    await showProvisionedCredentialsDialog(
      context: context,
      credentials: credentials,
    );
  }

  Future<void> _openEditAccount(
    AccountOverviewItem item,
    bool isSelfAccount,
  ) async {
    await showEditUserDialog(
      context: context,
      user: item.user,
      isCurrentSessionUser: isSelfAccount,
      onSubmit:
          ({
            required String name,
            required UserRole role,
            String? apartmentId,
            bool clearApartmentId = false,
          }) async {
            final controller = ref.read(accountsControllerProvider.notifier);
            final ok = await controller.updateAccount(
              item: item,
              name: name,
              role: role,
            );
            if (!mounted) return ok;

            if (ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conta e permissões atualizadas com sucesso.'),
                ),
              );
            } else {
              final err = ref.read(accountsControllerProvider).actionError;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(err ?? 'Erro ao atualizar conta.')),
              );
            }
            return ok;
          },
    );
  }

  Future<void> _handlePasswordReset(AccountOverviewItem item) async {
    final confirmed = await showConfirmPasswordResetDialog(
      context: context,
      user: item.user,
    );
    if (!confirmed || !mounted) return;

    final controller = ref.read(accountsControllerProvider.notifier);
    final ok = await controller.sendPasswordReset(item.user.email);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'E-mail de redefinição enviado para ${item.user.email}.',
          ),
        ),
      );
    } else {
      final err = ref.read(accountsControllerProvider).actionError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Erro ao enviar e-mail de redefinição.'),
        ),
      );
    }
  }

  Future<void> _handleToggleAccount(AccountOverviewItem item) async {
    final scopeSuffix = item.condominium != null
        ? ' (${item.condominium!.name})'
        : ' (Painel Admin)';

    final confirmed = await showConfirmStatusToggleDialog(
      context: context,
      entityLabel: 'conta',
      entityName: '${item.user.name}$scopeSuffix',
      currentlyActive: item.user.active,
    );
    if (!confirmed || !mounted) return;

    final controller = ref.read(accountsControllerProvider.notifier);
    final ok = await controller.toggleAccountActive(item);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.user.active
                ? 'Conta desativada com sucesso.'
                : 'Conta reativada com sucesso.',
          ),
        ),
      );
    } else {
      final err = ref.read(accountsControllerProvider).actionError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Erro ao alterar status da conta.')),
      );
    }
  }
}

class _GlobalAccountTile extends StatelessWidget {
  final AccountOverviewItem item;
  final bool isSelfAccount;
  final bool disabled;
  final VoidCallback onCopyEmail;
  final VoidCallback? onOpenCondominiumUsers;
  final VoidCallback onEdit;
  final VoidCallback onSendPasswordReset;
  final VoidCallback onToggleActive;

  const _GlobalAccountTile({
    required this.item,
    required this.isSelfAccount,
    required this.disabled,
    required this.onCopyEmail,
    required this.onOpenCondominiumUsers,
    required this.onEdit,
    required this.onSendPasswordReset,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = item.user;
    final initial = user.name.trim().isNotEmpty
        ? user.name.trim().substring(0, 1).toUpperCase()
        : '?';

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
                    ? (user.isAdmin
                          ? colorScheme.primaryContainer
                          : colorScheme.secondaryContainer)
                    : colorScheme.surfaceContainerHighest,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: user.active
                        ? (user.isAdmin
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSecondaryContainer)
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelfAccount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(Sua conta)',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
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
                    const SizedBox(height: 6),
                    if (item.isPlatformStandaloneAccount)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 15,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Acesso global ao Painel MedeJá Admin',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ActionChip(
                            avatar: const Icon(
                              Icons.apartment_outlined,
                              size: 16,
                            ),
                            label: Text(
                              '${item.condominium!.name} • ${item.administrator!.name}',
                            ),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Abrir contas deste condomínio',
                            onPressed: onOpenCondominiumUsers,
                          ),
                          if (item.condominiumTotalAccounts > 1)
                            Text(
                              '(${item.condominiumTotalAccounts} contas no condomínio)',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
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
                Tooltip(
                  message:
                      'Criada com senha temporária — aguardando primeiro acesso e troca de senha.',
                  child: Chip(
                    avatar: Icon(
                      Icons.key_outlined,
                      size: 16,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    label: const Text('1º acesso pendente'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.tertiaryContainer,
                  ),
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
                    case 'edit':
                      onEdit();
                      break;
                    case 'reset_password':
                      onSendPasswordReset();
                      break;
                    case 'open_condo':
                      onOpenCondominiumUsers?.call();
                      break;
                    case 'toggle_active':
                      onToggleActive();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar dados e perfil'),
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
                  if (onOpenCondominiumUsers != null)
                    const PopupMenuItem(
                      value: 'open_condo',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.apartment_outlined),
                        title: Text('Ver contas do condomínio'),
                      ),
                    ),
                  if (!isSelfAccount)
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

class _CreateGlobalAccountDialog extends ConsumerStatefulWidget {
  final String? initialAdministratorId;
  final String? initialCondominiumId;
  final UserRole? initialRole;

  const _CreateGlobalAccountDialog({
    this.initialAdministratorId,
    this.initialCondominiumId,
    this.initialRole,
  });

  @override
  ConsumerState<_CreateGlobalAccountDialog> createState() =>
      _CreateGlobalAccountDialogState();
}

class _CreateGlobalAccountDialogState
    extends ConsumerState<_CreateGlobalAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late final TextEditingController _tempPasswordController;

  late UserRole _selectedRole;
  String? _selectedAdministratorId;
  String? _selectedCondominiumId;
  bool _active = true;
  bool _obscurePassword = false;

  @override
  void initState() {
    super.initState();
    _tempPasswordController = TextEditingController(
      text: generateTemporaryPassword(),
    );

    final state = ref.read(accountsControllerProvider);
    final hasAnyCondominium = state.condominiumGroups.isNotEmpty;

    _selectedRole =
        widget.initialRole ??
        (hasAnyCondominium ? UserRole.user : UserRole.admin);

    if (widget.initialAdministratorId != null &&
        widget.initialCondominiumId != null) {
      _selectedAdministratorId = widget.initialAdministratorId;
      _selectedCondominiumId = widget.initialCondominiumId;
    } else if (state.condominiumsWithoutAccount.isNotEmpty) {
      final firstWithout = state.condominiumsWithoutAccount.first;
      _selectedAdministratorId = firstWithout.administrator.id;
      _selectedCondominiumId = firstWithout.condominium.id;
    } else if (state.condominiumGroups.isNotEmpty) {
      final first = state.condominiumGroups.first;
      _selectedAdministratorId = first.administrator.id;
      _selectedCondominiumId = first.condominium.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _tempPasswordController.dispose();
    super.dispose();
  }

  void _regeneratePassword() {
    setState(() {
      _tempPasswordController.text = generateTemporaryPassword();
      _obscurePassword = false;
    });
  }

  Future<void> _submit({
    required String? effectiveAdminId,
    required String? effectiveCondoId,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(accountsControllerProvider.notifier);

    ProvisionedUserCredentials? credentials;
    if (_selectedRole.isAdmin) {
      credentials = await controller.provisionPlatformAdminAccount(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        temporaryPassword: _tempPasswordController.text,
        active: _active,
      );
    } else {
      if (effectiveAdminId == null || effectiveCondoId == null) {
        return;
      }
      credentials = await controller.provisionAccount(
        administratorId: effectiveAdminId,
        condominiumId: effectiveCondoId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        temporaryPassword: _tempPasswordController.text,
        role: UserRole.user,
        active: _active,
      );
    }

    if (!mounted) return;
    if (credentials != null) {
      Navigator.pop(context, credentials);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final adminsWithCondos = state.administrators
        .where((admin) => state.groupsByAdministrator(admin.id).isNotEmpty)
        .toList();
    final hasAnyCondominium = adminsWithCondos.isNotEmpty;

    final effectiveAdminId =
        (_selectedAdministratorId != null &&
            adminsWithCondos.any((a) => a.id == _selectedAdministratorId))
        ? _selectedAdministratorId!
        : (adminsWithCondos.isNotEmpty ? adminsWithCondos.first.id : null);

    final condosForAdmin = effectiveAdminId != null
        ? state.groupsByAdministrator(effectiveAdminId)
        : const <CondominiumAccountGroup>[];

    final effectiveCondoId =
        (_selectedCondominiumId != null &&
            condosForAdmin.any(
              (g) => g.condominium.id == _selectedCondominiumId,
            ))
        ? _selectedCondominiumId!
        : (condosForAdmin.isNotEmpty
              ? condosForAdmin.first.condominium.id
              : null);

    final selectedGroup = (effectiveAdminId != null && effectiveCondoId != null)
        ? state.findGroup(effectiveAdminId, effectiveCondoId)
        : null;

    final canSubmit =
        !state.isSaving && (_selectedRole.isAdmin || hasAnyCondominium);

    return AlertDialog(
      title: const Text('Nova conta'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.actionError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      state.actionError!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<UserRole>(
                  key: ValueKey(_selectedRole),
                  initialValue: _selectedRole,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Perfil de acesso (Role) *',
                    helperText: _selectedRole.description,
                    helperMaxLines: 2,
                    prefixIcon: Icon(
                      _selectedRole.isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.smartphone_outlined,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    if (hasAnyCondominium)
                      const DropdownMenuItem(
                        value: UserRole.user,
                        child: Text(
                          'Comum / Operacional (Condomínio • App Mobile)',
                        ),
                      ),
                    const DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text(
                        'Administrador (Acesso ao Painel MedeJá Admin)',
                      ),
                    ),
                  ],
                  onChanged: state.isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                ),
                const SizedBox(height: 16),
                if (_selectedRole.isAdmin) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Conta Administrativa Global: poderá fazer login neste painel web MedeJá Admin e gerenciar administradoras, condomínios e contas.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey('adm_$effectiveAdminId'),
                    initialValue: effectiveAdminId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Administradora *',
                      prefixIcon: Icon(Icons.business_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: adminsWithCondos
                        .map(
                          (admin) => DropdownMenuItem<String>(
                            value: admin.id,
                            child: Text(
                              admin.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: state.isSaving
                        ? null
                        : (newAdminId) {
                            if (newAdminId == null) return;
                            final nextCondos = state.groupsByAdministrator(
                              newAdminId,
                            );
                            final preferred = nextCondos
                                .where((g) => !g.hasAccount)
                                .toList();
                            setState(() {
                              _selectedAdministratorId = newAdminId;
                              _selectedCondominiumId = preferred.isNotEmpty
                                  ? preferred.first.condominium.id
                                  : (nextCondos.isNotEmpty
                                        ? nextCondos.first.condominium.id
                                        : null);
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'condo_${effectiveAdminId}_$effectiveCondoId',
                    ),
                    initialValue: effectiveCondoId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Condomínio vinculado *',
                      prefixIcon: Icon(Icons.apartment_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: condosForAdmin.map((group) {
                      final statusTag = group.totalUsers == 0
                          ? 'Sem conta'
                          : '${group.totalUsers} conta(s)';
                      return DropdownMenuItem<String>(
                        value: group.condominium.id,
                        child: Text(
                          '${group.condominium.name} ($statusTag)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: state.isSaving
                        ? null
                        : (newCondoId) {
                            setState(() {
                              _selectedAdministratorId = effectiveAdminId;
                              _selectedCondominiumId = newCondoId;
                            });
                          },
                  ),
                  if (selectedGroup != null && selectedGroup.hasAccount) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este condomínio já possui ${selectedGroup.totalUsers} conta(s) vinculada(s). O comum é 1 conta por condomínio, mas você pode prosseguir para cadastrar um operador adicional.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  enabled: !state.isSaving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo *',
                    hintText: 'Ex.: João Silva',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Informe o nome completo (mínimo 3 caracteres).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  enabled: !state.isSaving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail de acesso *',
                    hintText: 'Ex.: leitura@condominio.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o e-mail de acesso.';
                    }
                    final email = value.trim().toLowerCase();
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(email)) {
                      return 'Informe um e-mail válido.';
                    }
                    final controller = ref.read(
                      accountsControllerProvider.notifier,
                    );
                    if (controller.hasAccountWithEmail(email)) {
                      return 'Este e-mail já está em uso por outra conta.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tempPasswordController,
                  enabled: !state.isSaving,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Senha temporária de 1º acesso *',
                    helperText: _selectedRole.isAdmin
                        ? 'Compartilhe com segurança com o novo administrador.'
                        : 'O usuário trocará esta senha ao entrar no app MedeJá.',
                    prefixIcon: const Icon(Icons.key_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Gerar nova senha temporária',
                          onPressed: state.isSaving
                              ? null
                              : _regeneratePassword,
                          icon: const Icon(Icons.autorenew),
                        ),
                        IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                  validator: validateTemporaryPassword,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Conta ativa'),
                  subtitle: const Text('Habilita acesso imediato ao sistema.'),
                  value: _active,
                  onChanged: state.isSaving
                      ? null
                      : (v) => setState(() => _active = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: !canSubmit
              ? null
              : () => _submit(
                  effectiveAdminId: effectiveAdminId,
                  effectiveCondoId: effectiveCondoId,
                ),
          icon: state.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add_outlined),
          label: Text(state.isSaving ? 'Criando...' : 'Criar conta'),
        ),
      ],
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
            Icon(icon, size: 30, color: colorScheme.primary),
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
