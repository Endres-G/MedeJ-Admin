import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';

class AdministratorsPage extends StatefulWidget {
  const AdministratorsPage({super.key});

  @override
  State<AdministratorsPage> createState() => _AdministratorsPageState();
}

class _AdministratorsPageState extends State<AdministratorsPage> {
  final AdministratorRepository _repository = AdministratorRepository();

  List<AdministratorModel> _administrators = [];
  List<AdministratorModel> _trashAdministrators = [];
  String _search = '';
  bool _isLoading = true;
  bool _showingTrash = false;

  @override
  void initState() {
    super.initState();
    _loadAdministrators();
  }

  Future<void> _loadAdministrators() async {
    try {
      setState(() => _isLoading = true);
      final activeList = await _repository.getAdministrators(includeDeleted: false);
      final trashList = await _repository.getDeletedAdministrators();

      if (!mounted) return;
      setState(() {
        _administrators = activeList;
        _trashAdministrators = trashList;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  List<AdministratorModel> get _currentList {
    final list = _showingTrash ? _trashAdministrators : _administrators;
    if (_search.trim().isEmpty) return list;
    final s = _search.toLowerCase();
    return list.where((a) => a.name.toLowerCase().contains(s) || a.email.toLowerCase().contains(s)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isSmall),
              const SizedBox(height: 24),
              _buildTrashTabs(context),
              const SizedBox(height: 20),
              _buildSummary(context),
              const SizedBox(height: 24),
              _buildSearchField(context),
              const SizedBox(height: 16),
              _buildAdministratorsList(context),
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
                'Administradoras',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gerenciamento de empresas contratantes e parceiras do MedeJá.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _showCreateAdministratorDialog,
          icon: const Icon(Icons.add),
          label: const Text('Nova administradora'),
        ),
      ],
    );
  }

  Widget _buildTrashTabs(BuildContext context) {
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment<bool>(
          value: false,
          label: Text('Ativas (${_administrators.length})'),
          icon: const Icon(Icons.business_outlined),
        ),
        ButtonSegment<bool>(
          value: true,
          label: Text('Lixeira (${_trashAdministrators.length})'),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
      selected: {_showingTrash},
      onSelectionChanged: (set) {
        setState(() => _showingTrash = set.first);
      },
    );
  }

  Widget _buildSummary(BuildContext context) {
    if (_showingTrash) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Itens na lixeira ficam desativados e não aparecem na operação. '
                  'Você pode restaurá-los ou excluí-los permanentemente com toda sua estrutura.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = _administrators.length;
    final active = _administrators.where((item) => item.active).length;
    final inactive = total - active;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total',
            value: '$total',
            icon: Icons.business_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Ativas',
            value: '$active',
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Inativas',
            value: '$inactive',
            icon: Icons.pause_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      onChanged: (value) => setState(() => _search = value),
      decoration: InputDecoration(
        hintText: _showingTrash ? 'Buscar na lixeira...' : 'Buscar administradora por nome ou e-mail...',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAdministratorsList(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }

    final list = _currentList;

    if (list.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Center(
            child: Column(
              children: [
                Icon(
                  _showingTrash ? Icons.delete_sweep_outlined : Icons.business_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  _showingTrash ? 'A lixeira está vazia.' : 'Nenhuma administradora cadastrada.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: list.map((admin) {
          final isTrash = _showingTrash;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: admin.active
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.business, color: admin.active ? Theme.of(context).colorScheme.onPrimaryContainer : null),
                ),
                title: Text(admin.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin.email),
                    if (admin.phone != null && admin.phone!.isNotEmpty) Text(admin.phone!),
                    if (isTrash && admin.deletedAt != null)
                      Text(
                        'Excluído em: ${DateFormat('dd/MM/yyyy HH:mm').format(admin.deletedAt!)}',
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                      ),
                  ],
                ),
                trailing: isTrash
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text('Restaurar'),
                            onPressed: () => _restoreAdmin(admin),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            tooltip: 'Excluir definitivamente',
                            onPressed: () => _confirmPermanentDelete(admin),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Mover para lixeira',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmMoveToTrash(admin),
                          ),
                          FilledButton.tonal(
                            onPressed: () => context.go(AppRoutes.administratorDetailsPath(admin.id)),
                            child: const Text('Abrir'),
                          ),
                        ],
                      ),
              ),
              const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _confirmMoveToTrash(AdministratorModel admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mover para lixeira?'),
        content: Text(
          'Deseja mover a administradora "${admin.name}" para a lixeira? '
          'Seus condomínios e contas ficarão inativos, mas você poderá restaurá-los a qualquer momento.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mover para lixeira'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.moveToTrash(admin.id);
      _loadAdministrators();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Administradora "${admin.name}" movida para a lixeira.')),
      );
    }
  }

  Future<void> _restoreAdmin(AdministratorModel admin) async {
    await _repository.restoreFromTrash(admin.id);
    _loadAdministrators();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Administradora "${admin.name}" restaurada com sucesso!')),
    );
  }

  Future<void> _confirmPermanentDelete(AdministratorModel admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir permanentemente?'),
        content: Text(
          'ATENÇÃO: Isso apagará DEFINITIVAMENTE a administradora "${admin.name}", '
          'TODOS os condomínios vinculados, blocos, apartamentos e histórico de leituras. '
          'Esta ação NÃO pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Tudo Definitivamente'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.permanentDeleteAdministrator(admin.id);
      _loadAdministrators();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Administradora "${admin.name}" e seus registros foram excluídos permanentemente.')),
      );
    }
  }

  Future<void> _showCreateAdministratorDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Administradora'),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome da Empresa *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail Comercial *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) return;
              await _repository.createAdministrator(
                AdministratorModel(
                  id: '',
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  active: true,
                ),
              );
              Navigator.pop(ctx);
              _loadAdministrators();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
