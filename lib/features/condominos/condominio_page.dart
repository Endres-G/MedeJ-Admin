import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/app/widgets/dashboard_card_widget.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/dashboard/dashboard_controller.dart';

class CondominiumsPage extends ConsumerStatefulWidget {
  const CondominiumsPage({super.key});

  @override
  ConsumerState<CondominiumsPage> createState() => _CondominiumsPageState();
}

class _CondominiumsPageState extends ConsumerState<CondominiumsPage> {
  String _search = '';
  String _selectedAdministratorId = 'Todos';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);

    final validAdminIds = {
      'Todos',
      ...state.administrators.map((a) => a.id),
    };
    final effectiveAdminFilter = validAdminIds.contains(_selectedAdministratorId)
        ? _selectedAdministratorId
        : 'Todos';

    final filtered = state.condominiums.where((item) {
      final query = _search.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          item.condominium.name.toLowerCase().contains(query) ||
          item.condominium.address.toLowerCase().contains(query) ||
          item.administrator.name.toLowerCase().contains(query);

      final matchesAdmin =
          effectiveAdminFilter == 'Todos' ||
          item.administrator.id == effectiveAdminFilter;

      return matchesSearch && matchesAdmin;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state, isSmall),
              const SizedBox(height: 24),
              if (state.isLoading)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (state.error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
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
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => ref
                                .read(dashboardControllerProvider.notifier)
                                .load(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                _buildSummary(state),
                const SizedBox(height: 24),
                if (state.condominiums.isNotEmpty) ...[
                  _buildFilters(state, effectiveAdminFilter, isSmall),
                  const SizedBox(height: 16),
                ],
                _buildList(context, state, filtered, isSmall),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DashboardState state,
    bool isSmall,
  ) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Condomínios',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Consulte os condomínios vinculados às administradoras contratantes.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );

    final actions = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: state.isLoading
              ? null
              : () => ref.read(dashboardControllerProvider.notifier).load(),
          icon: const Icon(Icons.refresh),
          label: const Text('Atualizar'),
        ),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.administrators),
          icon: const Icon(Icons.business_outlined),
          label: const Text('Por administradora'),
        ),
      ],
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 16), actions],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        actions,
      ],
    );
  }

  Widget _buildSummary(DashboardState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : (constraints.maxWidth >= 650 ? 2 : 1);
        const spacing = 16.0;
        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: DashboardCard(
                title: 'Total de condomínios',
                value: '${state.totalCondominiums}',
                icon: Icons.apartment_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardCard(
                title: 'Configuração completa',
                value: '${state.configuredCondominiums}',
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardCard(
                title: 'Configuração pendente',
                value: '${state.pendingConfigurationCondominiums}',
                icon: Icons.pending_actions_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(
    DashboardState state,
    String effectiveAdminFilter,
    bool isSmall,
  ) {
    final searchField = TextField(
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Buscar condomínio ou endereço...',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        suffixIcon: _search.isNotEmpty
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _search = '';
                  });
                },
                icon: const Icon(Icons.clear),
              )
            : null,
      ),
    );

    final adminDropdown = DropdownButtonFormField<String>(
      initialValue: effectiveAdminFilter,
      decoration: const InputDecoration(
        labelText: 'Administradora',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: 'Todos', child: Text('Todas')),
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
          _selectedAdministratorId = value;
        });
      },
    );

    if (isSmall) {
      return Column(
        children: [searchField, const SizedBox(height: 12), adminDropdown],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 16),
        SizedBox(width: 260, child: adminDropdown),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    DashboardState state,
    List<DashboardCondominiumItem> filtered,
    bool isSmall,
  ) {
    if (state.condominiums.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.apartment_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                const Text('Nenhum condomínio cadastrado.'),
                const SizedBox(height: 8),
                const Text(
                  'Os condomínios são vinculados a uma administradora contratante.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Nenhum condomínio encontrado.')),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(filtered.length, (index) {
          final item = filtered[index];
          final isComplete = item.isConfigurationComplete;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  child: Icon(
                    Icons.apartment_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                title: Text(
                  item.condominium.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Administradora: ${item.administrator.name}'),
                      if (item.condominium.address.trim().isNotEmpty)
                        Text(item.condominium.address),
                      Text(
                        '${item.blocksCount} blocos • '
                        '${item.apartmentsCount} apartamentos • '
                        '${item.usersCount} contas',
                      ),
                    ],
                  ),
                ),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      label: Text(item.configurationStatusLabel),
                      backgroundColor: isComplete
                          ? colorScheme.secondaryContainer
                          : colorScheme.tertiaryContainer,
                    ),
                    FilledButton.tonal(
                      onPressed: () {
                        context.go(
                          AppRoutes.condominiumDetailsPath(
                            item.condominium.id,
                            administratorId: item.administrator.id,
                          ),
                        );
                      },
                      child: const Text('Abrir'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Mover para lixeira',
                      onPressed: () => _handleMoveCondominiumToTrash(item),
                    ),
                  ],
                ),
              ),
              if (index < filtered.length - 1) const Divider(height: 1),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _handleMoveCondominiumToTrash(
    DashboardCondominiumItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mover condomínio para lixeira?'),
        content: Text(
          'Deseja mover o condomínio "${item.condominium.name}" para a lixeira?\n\n'
          'Suas medições, blocos e apartamentos ficarão suspensos na operação. '
          'O item permanecerá na Lixeira por 30 dias antes de ser excluído definitivamente de forma automática '
          '(você também pode restaurá-lo a qualquer momento na tela de Lixeira).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mover para lixeira'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(condominiumRepositoryProvider)
          .moveToTrash(item.administrator.id, item.condominium.id);
      ref.read(dashboardControllerProvider.notifier).load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Condomínio "${item.condominium.name}" movido para a lixeira.',
          ),
        ),
      );
    }
  }
}
