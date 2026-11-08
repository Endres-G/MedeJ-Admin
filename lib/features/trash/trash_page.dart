import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mede_ja_admin/app/widgets/dashboard_card_widget.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';

class DeletedCondominiumItem {
  final AdministratorModel administrator;
  final CondominiumModel condominium;

  const DeletedCondominiumItem({
    required this.administrator,
    required this.condominium,
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
  int _selectedTab = 0; // 0 = Administradoras, 1 = Condomínios

  List<AdministratorModel> _trashAdministrators = [];
  List<DeletedCondominiumItem> _trashCondominiums = [];

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

      // 1. Carrega administradoras deletadas
      final deletedAdmins = await adminRepo.getDeletedAdministrators();

      // 2. Carrega todos os administradores (ativos e deletados) para buscar condomínios na lixeira
      final allAdmins = await adminRepo.getAdministrators(includeDeleted: true);

      final List<DeletedCondominiumItem> deletedCondos = [];
      for (final admin in allAdmins) {
        final condos = await condoRepo.getDeletedCondominiumsByAdministrator(admin.id);
        for (final condo in condos) {
          deletedCondos.add(
            DeletedCondominiumItem(
              administrator: admin,
              condominium: condo,
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _trashAdministrators = deletedAdmins;
        _trashCondominiums = deletedCondos;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
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
          'seus blocos, apartamentos, usuários e todas as leituras de gás e água associadas.\n\n'
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
              else
                _buildCondominiumsList(context, filteredCondos),
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
                'Gerencie itens removidos da operação. Restaure itens a qualquer momento ou force a exclusão permanente.',
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
          children: [
            Icon(Icons.shield_outlined, color: theme.colorScheme.error),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Segurança de Dados: Itens movidos para a lixeira ficam inoperantes e ocultos no painel e no app mobile, '
                'mas seus dados de medição histórica são preservados até que você decida excluí-los em definitivo.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DashboardCard(
            title: 'Administradoras na Lixeira',
            value: _trashAdministrators.length.toString(),
            icon: Icons.business_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardCard(
            title: 'Condomínios na Lixeira',
            value: _trashCondominiums.length.toString(),
            icon: Icons.apartment_outlined,
          ),
        ),
      ],
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
            : 'Buscar condomínio por nome, endereço ou administradora...',
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
                const SizedBox(height: 2),
                Text(
                  deletedText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
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
                const SizedBox(height: 2),
                Text(
                  deletedText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
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
