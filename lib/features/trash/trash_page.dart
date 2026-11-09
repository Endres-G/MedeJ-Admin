import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mede_ja_admin/app/widgets/dashboard_card_widget.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';

class DeletedCondominiumItem {
  final AdministratorModel administrator;
  final CondominiumModel condominium;

  const DeletedCondominiumItem({
    required this.administrator,
    required this.condominium,
  });
}

class DeletedUserItem {
  final AdministratorModel administrator;
  final CondominiumModel condominium;
  final UserModel user;

  const DeletedUserItem({
    required this.administrator,
    required this.condominium,
    required this.user,
  });
}

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  bool _isLoading = true;
  String? _error;
  String _search = '';
  int _selectedTab = 0; // 0 = Administradoras, 1 = Condomínios, 2 = Usuários

  List<AdministratorModel> _trashAdministrators = [];
  List<DeletedCondominiumItem> _trashCondominiums = [];
  List<DeletedUserItem> _trashUsers = [];

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adminRepo = ref.read(administratorRepositoryProvider);
      final condoRepo = ref.read(condominiumRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      // 1. Carrega administradoras deletadas
      final deletedAdmins = await adminRepo.getDeletedAdministrators();

      // 2. Carrega todos os administradores (ativos e deletados) para buscar condomínios e usuários na lixeira
      final allAdmins = await adminRepo.getAdministrators(includeDeleted: true);

      final List<DeletedCondominiumItem> deletedCondos = [];
      final List<DeletedUserItem> deletedUsers = [];

      for (final admin in allAdmins) {
        // Carrega condomínios da lixeira
        final condosInTrash = await condoRepo.getDeletedCondominiumsByAdministrator(admin.id);
        for (final condo in condosInTrash) {
          deletedCondos.add(
            DeletedCondominiumItem(
              administrator: admin,
              condominium: condo,
            ),
          );
        }

        // Carrega condomínios gerais para buscar usuários na lixeira
        final allCondos = await condoRepo.getCondominiumsByAdministrator(
          admin.id,
          includeDeleted: true,
        );

        for (final condo in allCondos) {
          final usersInTrash = await userRepo.getDeletedUsers(admin.id, condo.id);
          for (final u in usersInTrash) {
            deletedUsers.add(
              DeletedUserItem(
                administrator: admin,
                condominium: condo,
                user: u,
              ),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _trashAdministrators = deletedAdmins;
        _trashCondominiums = deletedCondos;
        _trashUsers = deletedUsers;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Widget _buildRetentionBadge(DateTime? deletedAt) {
    final difference = deletedAt != null
        ? DateTime.now().difference(deletedAt).inDays
        : 0;
    final remaining = 30 - difference;

    final isUrgent = remaining <= 3;
    final label = remaining <= 0
        ? 'Exclusão definitiva automática em < 24h'
        : (remaining == 1
            ? 'Exclusão definitiva em 1 dia'
            : 'Exclusão definitiva em $remaining dias');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isUrgent ? Colors.red.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 13,
            color: isUrgent ? Colors.red.shade900 : Colors.orange.shade900,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUrgent ? Colors.red.shade900 : Colors.orange.shade900,
            ),
          ),
        ],
      ),
    );
  }

  // --- Ações de Administradora ---

  Future<void> _restoreAdministrator(AdministratorModel admin) async {
    try {
      final adminRepo = ref.read(administratorRepositoryProvider);
      await adminRepo.restoreFromTrash(admin.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Administradora "${admin.name}" restaurada com sucesso!')),
      );
      _loadTrash();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao restaurar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _permanentDeleteAdministrator(AdministratorModel admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Administradora Definitivamente?'),
        content: Text(
          'ATENÇÃO: Isso apagará DEFINITIVAMENTE a administradora "${admin.name}", '
          'TODOS os condomínios vinculados, blocos, apartamentos, usuários e histórico de medições.\n\n'
          'Esta ação NÃO pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Tudo Definitivamente'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final adminRepo = ref.read(administratorRepositoryProvider);
        await adminRepo.permanentDeleteAdministrator(admin.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Administradora "${admin.name}" e seus dados foram excluídos definitivamente.'),
          ),
        );
        _loadTrash();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // --- Ações de Condomínio ---

  Future<void> _restoreCondominium(DeletedCondominiumItem item) async {
    try {
      final condoRepo = ref.read(condominiumRepositoryProvider);
      await condoRepo.restoreFromTrash(item.administrator.id, item.condominium.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Condomínio "${item.condominium.name}" restaurado com sucesso!')),
      );
      _loadTrash();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao restaurar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _permanentDeleteCondominium(DeletedCondominiumItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Condomínio Definitivamente?'),
        content: Text(
          'ATENÇÃO: Isso apagará DEFINITIVAMENTE o condomínio "${item.condominium.name}", '
          'seus blocos, apartamentos, contas e todas as leituras de gás e água associadas.\n\n'
          'Esta ação NÃO pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Definitivamente'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final condoRepo = ref.read(condominiumRepositoryProvider);
        await condoRepo.permanentDeleteCondominium(item.administrator.id, item.condominium.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Condomínio "${item.condominium.name}" excluído definitivamente.'),
          ),
        );
        _loadTrash();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // --- Ações de Usuário / Conta ---

  Future<void> _restoreUser(DeletedUserItem item) async {
    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.restoreFromTrash(
        item.administrator.id,
        item.condominium.id,
        item.user.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conta de "${item.user.name}" restaurada com sucesso!')),
      );
      _loadTrash();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao restaurar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _permanentDeleteUser(DeletedUserItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Conta Definitivamente?'),
        content: Text(
          'ATENÇÃO: Isso apagará DEFINITIVAMENTE a conta de "${item.user.name}" (${item.user.email}) '
          'do sistema.\n\n'
          'Esta ação NÃO pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Definitivamente'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final userRepo = ref.read(userRepositoryProvider);
        await userRepo.permanentDeleteUser(
          item.administrator.id,
          item.condominium.id,
          item.user.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conta de "${item.user.name}" excluída definitivamente.'),
          ),
        );
        _loadTrash();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();

    final filteredAdmins = _trashAdministrators.where((a) {
      if (query.isEmpty) return true;
      return a.name.toLowerCase().contains(query) ||
          a.email.toLowerCase().contains(query) ||
          (a.phone?.toLowerCase().contains(query) ?? false);
    }).toList();

    final filteredCondos = _trashCondominiums.where((c) {
      if (query.isEmpty) return true;
      return c.condominium.name.toLowerCase().contains(query) ||
          c.condominium.address.toLowerCase().contains(query) ||
          c.administrator.name.toLowerCase().contains(query);
    }).toList();

    final filteredUsers = _trashUsers.where((u) {
      if (query.isEmpty) return true;
      return u.user.name.toLowerCase().contains(query) ||
          u.user.email.toLowerCase().contains(query) ||
          u.condominium.name.toLowerCase().contains(query) ||
          u.administrator.name.toLowerCase().contains(query);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 720;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isSmall),
              const SizedBox(height: 24),
              _buildInfoBanner(context),
              const SizedBox(height: 24),
              _buildSummaryCards(context),
              const SizedBox(height: 24),
              _buildTabSelector(context),
              const SizedBox(height: 20),
              _buildSearchBar(context),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Erro ao carregar lixeira: $_error'),
                  ),
                )
              else if (_selectedTab == 0)
                _buildAdministratorsList(context, filteredAdmins)
              else if (_selectedTab == 1)
                _buildCondominiumsList(context, filteredCondos)
              else
                _buildUsersList(context, filteredUsers),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lixeira e Recuperação',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Itens removidos ficam suspensos na operação por 30 dias. '
                'Você pode restaurá-los com integridade total ou forçar a exclusão imediata.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: _isLoading ? null : _loadTrash,
          tooltip: 'Atualizar lixeira',
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: theme.colorScheme.error),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Política de Segurança e Retenção (30 dias)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Todos os itens movidos para a lixeira (administradoras, condomínios e contas de usuários) '
                    'permanecem suspensos e guardados por 30 dias a partir da data de exclusão. '
                    'Após esse prazo de 30 dias, o sistema exclui definitivamente os dados de forma automática.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 800;
        final cardWidth = isSmall
            ? constraints.maxWidth
            : (constraints.maxWidth - 32) / 3;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Administradoras na Lixeira',
                value: _trashAdministrators.length.toString(),
                icon: Icons.business_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Condomínios na Lixeira',
                value: _trashCondominiums.length.toString(),
                icon: Icons.apartment_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Contas na Lixeira',
                value: _trashUsers.length.toString(),
                icon: Icons.people_outline,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        ButtonSegment<int>(
          value: 0,
          label: Text('Administradoras (${_trashAdministrators.length})'),
          icon: const Icon(Icons.business_outlined),
        ),
        ButtonSegment<int>(
          value: 1,
          label: Text('Condomínios (${_trashCondominiums.length})'),
          icon: const Icon(Icons.apartment_outlined),
        ),
        ButtonSegment<int>(
          value: 2,
          label: Text('Contas (${_trashUsers.length})'),
          icon: const Icon(Icons.people_outline),
        ),
      ],
      selected: {_selectedTab},
      onSelectionChanged: (set) {
        setState(() => _selectedTab = set.first);
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: _selectedTab == 0
            ? 'Buscar administradora por nome, e-mail ou telefone...'
            : (_selectedTab == 1
                ? 'Buscar condomínio por nome, endereço ou administradora...'
                : 'Buscar conta por nome, e-mail, condomínio ou administradora...'),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _search.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _search = ''),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      onChanged: (val) => setState(() => _search = val),
    );
  }

  Widget _buildAdministratorsList(
    BuildContext context,
    List<AdministratorModel> admins,
  ) {
    if (admins.isEmpty) {
      return _buildEmptyState(
        icon: Icons.business_outlined,
        title: 'Nenhuma administradora na lixeira',
        subtitle: _search.isNotEmpty
            ? 'Nenhum resultado corresponde à sua busca.'
            : 'Todas as administradoras cadastradas estão ativas.',
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: admins.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final admin = admins[index];
          final deletedText = admin.deletedAt != null
              ? 'Excluído em ${_dateFormat.format(admin.deletedAt!)}'
              : 'Na lixeira';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            ),
            title: Text(
              admin.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('E-mail: ${admin.email} • ${admin.phone ?? 'Sem telefone'}'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      deletedText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    _buildRetentionBadge(admin.deletedAt),
                  ],
                ),
              ],
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _restoreAdministrator(admin),
                  icon: const Icon(Icons.restore, color: Colors.green),
                  label: const Text('Restaurar', style: TextStyle(color: Colors.green)),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _permanentDeleteAdministrator(admin),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Excluir definitivo'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCondominiumsList(
    BuildContext context,
    List<DeletedCondominiumItem> items,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.apartment_outlined,
        title: 'Nenhum condomínio na lixeira',
        subtitle: _search.isNotEmpty
            ? 'Nenhum condomínio encontrado com os filtros atuais.'
            : 'Todos os condomínios estão ativos no painel.',
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          final condo = item.condominium;
          final deletedText = condo.deletedAt != null
              ? 'Excluído em ${_dateFormat.format(condo.deletedAt!)}'
              : 'Na lixeira';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              child: Icon(Icons.apartment_outlined, color: Theme.of(context).colorScheme.error),
            ),
            title: Row(
              children: [
                Text(
                  condo.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    'Admin: ${item.administrator.name}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(condo.address.isNotEmpty ? condo.address : 'Sem endereço informado'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      deletedText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    _buildRetentionBadge(condo.deletedAt),
                  ],
                ),
              ],
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _restoreCondominium(item),
                  icon: const Icon(Icons.restore, color: Colors.green),
                  label: const Text('Restaurar', style: TextStyle(color: Colors.green)),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _permanentDeleteCondominium(item),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Excluir definitivo'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersList(
    BuildContext context,
    List<DeletedUserItem> items,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'Nenhuma conta na lixeira',
        subtitle: _search.isNotEmpty
            ? 'Nenhuma conta encontrada com os filtros atuais.'
            : 'Todas as contas de usuários estão ativas no painel.',
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          final user = item.user;
          final deletedText = user.deletedAt != null
              ? 'Excluído em ${_dateFormat.format(user.deletedAt!)}'
              : 'Na lixeira';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.error),
            ),
            title: Row(
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    user.role.label,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('E-mail: ${user.email} • Condomínio: ${item.condominium.name} (${item.administrator.name})'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      deletedText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    _buildRetentionBadge(user.deletedAt),
                  ],
                ),
              ],
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _restoreUser(item),
                  icon: const Icon(Icons.restore, color: Colors.green),
                  label: const Text('Restaurar', style: TextStyle(color: Colors.green)),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _permanentDeleteUser(item),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Excluir definitivo'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
