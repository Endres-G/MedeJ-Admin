import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/app/widgets/dashboard_card_widget.dart';
import 'package:mede_ja_admin/features/dashboard/dashboard_controller.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _search = '';
  String _configFilter = 'Todos';

  List<DashboardCondominiumItem> _filterCondominiums(
    List<DashboardCondominiumItem> items,
  ) {
    final query = _search.trim().toLowerCase();

    return items.where((item) {
      final matchesSearch =
          query.isEmpty ||
          item.condominium.name.toLowerCase().contains(query) ||
          item.condominium.address.toLowerCase().contains(query) ||
          item.administrator.name.toLowerCase().contains(query);

      final matchesFilter = switch (_configFilter) {
        'Completa' => item.isConfigurationComplete,
        'Pendente' => !item.isConfigurationComplete,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state, isSmall),
              const SizedBox(height: 32),
              if (state.isLoading)
                _buildLoadingState()
              else if (state.error != null)
                _buildErrorState(context, state.error!)
              else ...[
                _buildSummaryCards(context, state),
                if (state.pendingConfigurationCondominiums > 0) ...[
                  const SizedBox(height: 24),
                  _buildOperationalBanner(context, state),
                ],
                const SizedBox(height: 36),
                _buildCondominiumsSection(context, state, isSmall),
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
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Visão geral e indicadores operacionais reais do MedeJá.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );

    final refreshButton = OutlinedButton.icon(
      onPressed: state.isLoading
          ? null
          : () => ref.read(dashboardControllerProvider.notifier).load(),
      icon: const Icon(Icons.refresh),
      label: const Text('Atualizar'),
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleSection, const SizedBox(height: 16), refreshButton],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleSection),
        const SizedBox(width: 16),
        refreshButton,
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 56, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando indicadores da plataforma...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Não foi possível carregar o Dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(dashboardControllerProvider.notifier).load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DashboardState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1100) {
          columns = 4;
        } else if (constraints.maxWidth >= 700) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 16.0;

        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        final adminsSubtitle = state.totalAdministrators > 0
            ? '${state.activeAdministrators} ${_pluralWord(state.activeAdministrators, 'ativa', 'ativas')}'
            : 'Nenhuma cadastrada';

        final condosSubtitle = state.totalCondominiums > 0
            ? '${state.configuredCondominiums} com config. completa'
            : 'Nenhum cadastrado';

        final apartmentsSubtitle = state.totalBlocks > 0
            ? 'em ${_pluralize(state.totalBlocks, 'bloco', 'blocos')}'
            : 'Nenhum bloco cadastrado';

        final usersSubtitle = state.totalUsers > 0
            ? '${state.activeUsers} ${_pluralWord(state.activeUsers, 'ativo', 'ativos')}'
            : 'Nenhum vinculado';

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Administradoras',
                value: '${state.totalAdministrators}',
                subtitle: adminsSubtitle,
                icon: Icons.business_outlined,
                onTap: () => context.go(AppRoutes.administrators),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Condomínios',
                value: '${state.totalCondominiums}',
                subtitle: condosSubtitle,
                icon: Icons.apartment_outlined,
                onTap: () => context.go(AppRoutes.condominiums),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Apartamentos',
                value: '${state.totalApartments}',
                subtitle: apartmentsSubtitle,
                icon: Icons.home_work_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Usuários',
                value: '${state.totalUsers}',
                subtitle: usersSubtitle,
                icon: Icons.people_outline,
                onTap: () => context.go(AppRoutes.accounts),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOperationalBanner(BuildContext context, DashboardState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = state.pendingConfigurationCondominiums;

    return Card(
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_pluralize(count, 'condomínio possui', 'condomínios possuem')} '
                'etapas de configuração pendentes (blocos, apartamentos ou contas).',
                style: TextStyle(color: colorScheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCondominiumsSection(
    BuildContext context,
    DashboardState state,
    bool isSmall,
  ) {
    final filtered = _filterCondominiums(state.condominiums);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Condomínios',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.administrators),
              icon: const Icon(Icons.business_outlined),
              label: const Text('Administradoras'),
            ),
          ],
        ),
        if (state.condominiums.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildFilters(isSmall),
        ],
        const SizedBox(height: 16),
        if (state.condominiums.isEmpty)
          _buildEmptyCondominiumsState(context, state)
        else if (filtered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhum condomínio encontrado para os filtros aplicados.',
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(filtered.length, (index) {
                final item = filtered[index];
                return Column(
                  children: [
                    _DashboardCondominiumTile(
                      item: item,
                      isSmall: isSmall,
                      onOpenCondominium: () {
                        context.go(
                          AppRoutes.condominiumDetailsPath(
                            item.condominium.id,
                            administratorId: item.administrator.id,
                          ),
                        );
                      },
                      onOpenAdministrator: () {
                        context.go(
                          AppRoutes.administratorDetailsPath(
                            item.administrator.id,
                          ),
                        );
                      },
                    ),
                    if (index < filtered.length - 1) const Divider(height: 1),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildFilters(bool isSmall) {
    final searchField = TextField(
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Buscar por condomínio, endereço ou administradora...',
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

    final statusDropdown = DropdownButtonFormField<String>(
      initialValue: _configFilter,
      decoration: const InputDecoration(
        labelText: 'Configuração',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Todos', child: Text('Todos')),
        DropdownMenuItem(value: 'Completa', child: Text('Completa')),
        DropdownMenuItem(value: 'Pendente', child: Text('Incompleta')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _configFilter = value;
        });
      },
    );

    if (isSmall) {
      return Column(
        children: [searchField, const SizedBox(height: 12), statusDropdown],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 16),
        SizedBox(width: 220, child: statusDropdown),
      ],
    );
  }

  Widget _buildEmptyCondominiumsState(
    BuildContext context,
    DashboardState state,
  ) {
    final hasAdmins = state.totalAdministrators > 0;

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
              Text(
                hasAdmins
                    ? 'Nenhum condomínio vinculado às administradoras.'
                    : 'Nenhuma administradora cadastrada.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                hasAdmins
                    ? 'Acesse uma administradora para cadastrar o primeiro condomínio.'
                    : 'Cadastre uma administradora contratante para iniciar a operação no MedeJá.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.administrators),
                icon: const Icon(Icons.business_outlined),
                label: Text(
                  hasAdmins
                      ? 'Ir para Administradoras'
                      : 'Cadastrar administradora',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCondominiumTile extends StatelessWidget {
  final DashboardCondominiumItem item;
  final bool isSmall;
  final VoidCallback onOpenCondominium;
  final VoidCallback onOpenAdministrator;

  const _DashboardCondominiumTile({
    required this.item,
    required this.isSmall,
    required this.onOpenCondominium,
    required this.onOpenAdministrator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isComplete = item.isConfigurationComplete;
    final hasAddress = item.condominium.address.trim().isNotEmpty;

    final metricsText =
        '${_pluralize(item.blocksCount, 'bloco', 'blocos')} • '
        '${_pluralize(item.apartmentsCount, 'apartamento', 'apartamentos')} • '
        '${_pluralize(item.usersCount, 'conta', 'contas')}';

    final pendingText = !isComplete
        ? 'Pendente: ${item.pendingSteps.join(', ')}'
        : null;

    final trailingControls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!item.condominium.active)
          Chip(
            label: const Text('Inativo'),
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
        Chip(
          label: Text(item.configurationStatusLabel),
          backgroundColor: isComplete
              ? colorScheme.secondaryContainer
              : colorScheme.tertiaryContainer,
        ),
        FilledButton.tonal(
          onPressed: onOpenCondominium,
          child: const Text('Abrir'),
        ),
      ],
    );

    final subtitleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onOpenAdministrator,
          child: Text(
            'Administradora: ${item.administrator.name}',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (hasAddress) ...[
          const SizedBox(height: 2),
          Text(item.condominium.address),
        ],
        const SizedBox(height: 2),
        Text(metricsText),
        if (pendingText != null) ...[
          const SizedBox(height: 2),
          Text(
            pendingText,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );

    if (isSmall) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.apartment_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.condominium.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            subtitleColumn,
            const SizedBox(height: 12),
            trailingControls,
          ],
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: CircleAvatar(
        child: Icon(Icons.apartment_outlined, color: colorScheme.primary),
      ),
      title: Text(
        item.condominium.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: subtitleColumn,
      ),
      trailing: trailingControls,
    );
  }
}

String _pluralWord(int count, String singular, String plural) {
  return count == 1 ? singular : plural;
}

String _pluralize(int count, String singular, String plural) {
  return '$count ${_pluralWord(count, singular, plural)}';
}
