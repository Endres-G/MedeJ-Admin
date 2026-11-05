import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/condominos/structure_dialogs.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';

class CondominiumDetailsPage extends ConsumerStatefulWidget {
  final String condominiumId;
  final String? administratorId;

  const CondominiumDetailsPage({
    super.key,
    required this.condominiumId,
    this.administratorId,
  });

  @override
  ConsumerState<CondominiumDetailsPage> createState() =>
      _CondominiumDetailsPageState();
}

class _CondominiumDetailsPageState
    extends ConsumerState<CondominiumDetailsPage> {
  static const int _initialApartmentChipsLimit = 48;

  String _structureSearch = '';
  final Set<String> _expandedFullBlocks = <String>{};

  CondominiumScope get _scope => CondominiumScope(
    condominiumId: widget.condominiumId,
    administratorId: widget.administratorId,
  );

  String? _effectiveAdminId(CondominiumDetailsState state) {
    final resolved = state.resolvedAdministratorId?.trim();
    if (resolved != null && resolved.isNotEmpty) return resolved;
    final fromWidget = widget.administratorId?.trim();
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(condominiumDetailsControllerProvider(_scope));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 760;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, state),
              const SizedBox(height: 20),
              if (state.isLoading && state.condominium == null)
                _buildLoadingCard()
              else if (state.error != null && state.condominium == null)
                _buildErrorCard(context, state.error!)
              else if (state.condominium != null) ...[
                _buildHeader(context, state, state.condominium!, isSmall),
                const SizedBox(height: 24),
                _buildConfigurationProgress(context, state, isSmall),
                const SizedBox(height: 24),
                _buildSummary(context, state),
                const SizedBox(height: 32),
                _buildBlocksAndApartmentsSection(context, state, isSmall),
                const SizedBox(height: 32),
                _buildUsersSection(context, state, isSmall),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, CondominiumDetailsState state) {
    final adminId = _effectiveAdminId(state);
    final adminName = state.administrator?.name.trim() ?? '';
    final backLabel = adminId != null
        ? (adminName.isNotEmpty
              ? 'Voltar para $adminName'
              : 'Voltar para Administradora')
        : 'Voltar para Condomínios';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: TextButton.icon(
            onPressed: () {
              if (adminId != null) {
                context.go(AppRoutes.administratorDetailsPath(adminId));
              } else {
                context.go(AppRoutes.condominiums);
              }
            },
            icon: const Icon(Icons.arrow_back),
            label: Text(backLabel, overflow: TextOverflow.ellipsis),
          ),
        ),
        IconButton(
          tooltip: 'Atualizar dados',
          onPressed: state.isLoading
              ? null
              : () => ref
                    .read(
                      condominiumDetailsControllerProvider(_scope).notifier,
                    )
                    .load(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 56, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando dados do condomínio...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
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
                  'Não foi possível carregar o condomínio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref
                      .read(
                        condominiumDetailsControllerProvider(_scope).notifier,
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
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CondominiumDetailsState state,
    CondominiumModel condominium,
    bool isSmall,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final adminId = _effectiveAdminId(state);

    final info = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          child: Icon(
            Icons.apartment_outlined,
            size: 30,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                condominium.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (condominium.address.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        condominium.address,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    label: Text(condominium.active ? 'Ativo' : 'Inativo'),
                    backgroundColor: condominium.active
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHighest,
                  ),
                  if (state.administrator != null)
                    ActionChip(
                      avatar: Icon(
                        Icons.business_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      label: Text(
                        'Administradora: ${state.administrator!.name}',
                      ),
                      onPressed: adminId == null
                          ? null
                          : () => context.go(
                              AppRoutes.administratorDetailsPath(adminId),
                            ),
                    ),
                  if (condominium.createdAt != null)
                    Text(
                      'Desde ${_formatDate(condominium.createdAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: state.isSaving
              ? null
              : () => _openEditCondominiumDialog(condominium),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
        ),
        OutlinedButton.icon(
          onPressed: state.isSaving
              ? null
              : () => _handleToggleCondominium(condominium),
          icon: Icon(
            condominium.active
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
          ),
          label: Text(condominium.active ? 'Desativar' : 'Ativar'),
        ),
      ],
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [info, const SizedBox(height: 16), actions],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: info),
        const SizedBox(width: 16),
        actions,
      ],
    );
  }

  Widget _buildConfigurationProgress(
    BuildContext context,
    CondominiumDetailsState state,
    bool isSmall,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isComplete = state.isConfigurationComplete;
    final adminId = _effectiveAdminId(state);

    final hasBlocks = state.totalBlocks > 0;
    final hasApartmentsAllBlocks =
        hasBlocks &&
        state.totalApartments > 0 &&
        state.blocksWithoutApartments == 0;
    final hasUsers = state.totalUsers > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete
                      ? Icons.verified_outlined
                      : Icons.fact_check_outlined,
                  color: isComplete
                      ? colorScheme.primary
                      : colorScheme.tertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isComplete
                        ? 'Configuração do condomínio completa'
                        : 'Progresso da configuração operacional',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text('${(state.configurationProgress * 100).round()}%'),
                  backgroundColor: isComplete
                      ? colorScheme.secondaryContainer
                      : colorScheme.tertiaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: state.configurationProgress),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StepStatusChip(label: '1. Informações', done: true),
                _StepStatusChip(
                  label: '2. Blocos (${state.totalBlocks})',
                  done: hasBlocks,
                  onTap: () => context.go(
                    AppRoutes.newBlockPath(
                      widget.condominiumId,
                      administratorId: adminId,
                    ),
                  ),
                ),
                _StepStatusChip(
                  label: '3. Apartamentos (${state.totalApartments})',
                  done: hasApartmentsAllBlocks,
                  onTap: hasBlocks
                      ? () => context.go(
                          AppRoutes.newApartmentPath(
                            widget.condominiumId,
                            administratorId: adminId,
                          ),
                        )
                      : null,
                ),
                _StepStatusChip(
                  label: '4. Contas (${state.totalUsers})',
                  done: hasUsers,
                  onTap: () => context.go(
                    AppRoutes.condominiumUsersPath(
                      widget.condominiumId,
                      administratorId: adminId,
                    ),
                  ),
                ),
              ],
            ),
            if (state.blocksWithoutApartments > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Atenção: ${_pluralize(state.blocksWithoutApartments, 'bloco ainda não possui', 'blocos ainda não possuem')} apartamentos cadastrados.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CondominiumDetailsState state) {
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
              child: _SummaryCard(
                title: 'Blocos',
                value: '${state.totalBlocks}',
                subtitle:
                    '${state.activeBlocks} ${_pluralWord(state.activeBlocks, 'ativo', 'ativos')}',
                icon: Icons.domain_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Apartamentos',
                value: '${state.totalApartments}',
                subtitle:
                    '${state.activeApartments} ${_pluralWord(state.activeApartments, 'ativo', 'ativos')}',
                icon: Icons.home_work_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Contas vinculadas',
                value: '${state.totalUsers}',
                subtitle:
                    '${state.activeUsers} ${_pluralWord(state.activeUsers, 'ativa', 'ativas')}',
                icon: Icons.people_outline,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlocksAndApartmentsSection(
    BuildContext context,
    CondominiumDetailsState state,
    bool isSmall,
  ) {
    final adminId = _effectiveAdminId(state);
    final blocksRoute = AppRoutes.condominiumBlocksPath(
      widget.condominiumId,
      administratorId: adminId,
    );
    final newBlockRoute = AppRoutes.newBlockPath(
      widget.condominiumId,
      administratorId: adminId,
    );
    final apartmentsRoute = AppRoutes.condominiumApartmentsPath(
      widget.condominiumId,
      administratorId: adminId,
    );
    final newApartmentRoute = AppRoutes.newApartmentPath(
      widget.condominiumId,
      administratorId: adminId,
    );

    final headerTitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blocos e apartamentos',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Visualize a estrutura física real do condomínio e adicione blocos ou apartamentos.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final headerActions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.go(blocksRoute),
          icon: const Icon(Icons.domain_outlined),
          label: const Text('Gerenciar blocos'),
        ),
        if (state.totalBlocks > 0)
          OutlinedButton.icon(
            onPressed: () => context.go(apartmentsRoute),
            icon: const Icon(Icons.list_alt_outlined),
            label: const Text('Lista de apartamentos'),
          ),
        if (state.totalBlocks > 0)
          FilledButton.tonalIcon(
            onPressed: () => context.go(newApartmentRoute),
            icon: const Icon(Icons.add_home_work_outlined),
            label: const Text('Novo apartamento'),
          ),
        FilledButton.icon(
          onPressed: () => context.go(newBlockRoute),
          icon: const Icon(Icons.add),
          label: const Text('Novo bloco'),
        ),
      ],
    );

    final query = _structureSearch.trim().toLowerCase();
    final filteredBlocks = state.blocks.where((item) {
      if (query.isEmpty) return true;
      if (item.block.name.toLowerCase().contains(query)) return true;
      return item.apartments.any((a) => a.name.toLowerCase().contains(query));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isSmall) ...[
          headerTitle,
          const SizedBox(height: 14),
          headerActions,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: headerTitle),
              const SizedBox(width: 16),
              Flexible(child: headerActions),
            ],
          ),
        const SizedBox(height: 16),

        if (state.blocks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.domain_disabled_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum bloco cadastrado neste condomínio.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Comece criando o primeiro bloco (ex.: Bloco A ou Bloco Único) para em seguida cadastrar os apartamentos.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => context.go(newBlockRoute),
                      icon: const Icon(Icons.add),
                      label: const Text('Criar primeiro bloco'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          TextField(
            onChanged: (value) {
              setState(() {
                _structureSearch = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Filtrar por nome do bloco ou número do apartamento...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _structureSearch.isNotEmpty
                  ? IconButton(
                      tooltip: 'Limpar filtro',
                      onPressed: () {
                        setState(() {
                          _structureSearch = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          if (filteredBlocks.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Nenhum bloco ou apartamento encontrado para o filtro informado.',
                  ),
                ),
              ),
            )
          else
            Column(
              children: filteredBlocks.map((blockItem) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildBlockStructureCard(
                    context: context,
                    state: state,
                    blockItem: blockItem,
                    searchQuery: query,
                    isSmall: isSmall,
                  ),
                );
              }).toList(),
            ),
        ],
      ],
    );
  }

  Widget _buildBlockStructureCard({
    required BuildContext context,
    required CondominiumDetailsState state,
    required BlockOverviewItem blockItem,
    required String searchQuery,
    required bool isSmall,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final adminId = _effectiveAdminId(state);
    final block = blockItem.block;

    final blockMatchesDirectly =
        searchQuery.isEmpty || block.name.toLowerCase().contains(searchQuery);

    final visibleApartments = blockMatchesDirectly
        ? blockItem.apartments
        : blockItem.apartments
              .where((a) => a.name.toLowerCase().contains(searchQuery))
              .toList();

    final showAll =
        searchQuery.isNotEmpty || _expandedFullBlocks.contains(block.id);
    final hasMoreApartments =
        !showAll && visibleApartments.length > _initialApartmentChipsLimit;
    final displayedApartments = hasMoreApartments
        ? visibleApartments.sublist(0, _initialApartmentChipsLimit)
        : visibleApartments;

    final addApartmentToBlockRoute = AppRoutes.newApartmentPath(
      widget.condominiumId,
      administratorId: adminId,
      blockId: block.id,
    );
    final blockDetailsRoute = AppRoutes.blockDetailsPath(
      widget.condominiumId,
      block.id,
      administratorId: adminId,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: block.active
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.domain_outlined,
                        color: block.active
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              block.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (!block.active) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: const Text('Inativo'),
                                visualDensity: VisualDensity.compact,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          blockItem.totalApartments == 0
                              ? 'Nenhum apartamento cadastrado'
                              : _pluralize(
                                  blockItem.totalApartments,
                                  'apartamento cadastrado',
                                  'apartamentos cadastrados',
                                ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Editar nome do bloco',
                      onPressed: state.isSaving
                          ? null
                          : () => _openEditBlockDialog(block),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(addApartmentToBlockRoute),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Apartamentos'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => context.go(blockDetailsRoute),
                      child: const Text('Detalhes do bloco'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            if (blockItem.apartments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Este bloco ainda não possui apartamentos. Cadastre individualmente ou gere em lote.',
                          ),
                        ),
                      ],
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.go(addApartmentToBlockRoute),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: const Text('Cadastrar apartamentos'),
                    ),
                  ],
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: displayedApartments.map((apartment) {
                  return ActionChip(
                    avatar: Icon(
                      apartment.active
                          ? Icons.home_outlined
                          : Icons.pause_circle_outline,
                      size: 16,
                      color: apartment.active
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                    label: Text(
                      apartment.name,
                      style: TextStyle(
                        decoration: apartment.active
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    tooltip: apartment.active
                        ? 'Clique para editar o apartamento ${apartment.name}'
                        : 'Apartamento ${apartment.name} (Inativo) - clique para editar',
                    backgroundColor: apartment.active
                        ? null
                        : colorScheme.surfaceContainerHighest,
                    onPressed: state.isSaving
                        ? null
                        : () => _openEditApartmentDialog(block, apartment),
                  );
                }).toList(),
              ),
              if (hasMoreApartments) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _expandedFullBlocks.add(block.id);
                    });
                  },
                  icon: const Icon(Icons.expand_more),
                  label: Text(
                    'Mostrar todos os ${visibleApartments.length} apartamentos deste bloco',
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsersSection(
    BuildContext context,
    CondominiumDetailsState state,
    bool isSmall,
  ) {
    final adminId = _effectiveAdminId(state);
    final usersRoute = AppRoutes.condominiumUsersPath(
      widget.condominiumId,
      administratorId: adminId,
    );
    final newUserRoute = AppRoutes.newCondominiumUserPath(
      widget.condominiumId,
      administratorId: adminId,
    );

    final apartmentsById = <String, ApartmentWithBlockItem>{
      for (final item in state.allApartments) item.apartment.id: item,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Contas e usuários',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: () => context.go(usersRoute),
              icon: const Icon(Icons.people_outline),
              label: const Text('Gerenciar contas'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.users.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 42,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Nenhuma conta vinculada a este condomínio.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () => context.go(newUserRoute),
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Criar conta do condomínio'),
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
              children: List.generate(state.users.length, (index) {
                final user = state.users[index];
                final linkedApartment = user.apartmentId != null
                    ? apartmentsById[user.apartmentId!]
                    : null;

                return Column(
                  children: [
                    _UserTile(user: user, linkedApartment: linkedApartment),
                    if (index < state.users.length - 1)
                      const Divider(height: 1),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Future<void> _openEditCondominiumDialog(CondominiumModel condominium) async {
    await showEditCondominiumDialog(
      context: context,
      condominium: condominium,
      onSubmit: ({required String name, required String address}) async {
        final controller = ref.read(
          condominiumDetailsControllerProvider(_scope).notifier,
        );
        final ok = await controller.updateCondominium(
          name: name,
          address: address,
        );
        if (!mounted) return ok;

        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Condomínio atualizado com sucesso.'),
            ),
          );
        } else {
          final error = ref
              .read(condominiumDetailsControllerProvider(_scope))
              .actionError;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Erro ao atualizar condomínio.'),
            ),
          );
        }
        return ok;
      },
    );
  }

  Future<void> _handleToggleCondominium(CondominiumModel condominium) async {
    final confirmed = await showConfirmStatusToggleDialog(
      context: context,
      entityLabel: 'condomínio',
      entityName: condominium.name,
      currentlyActive: condominium.active,
    );
    if (!confirmed || !mounted) return;

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );
    final ok = await controller.toggleCondominiumActive();
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            condominium.active
                ? 'Condomínio desativado com sucesso.'
                : 'Condomínio reativado com sucesso.',
          ),
        ),
      );
    } else {
      final error = ref
          .read(condominiumDetailsControllerProvider(_scope))
          .actionError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Erro ao alterar status.')),
      );
    }
  }

  Future<void> _openEditBlockDialog(BlockModel block) async {
    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );

    await showEditBlockDialog(
      context: context,
      block: block,
      isDuplicateName: (candidate) =>
          controller.hasBlockWithName(candidate, ignoreBlockId: block.id),
      onSubmit: (name) async {
        final ok = await controller.updateBlock(block: block, name: name);
        if (!mounted) return ok;

        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bloco atualizado com sucesso.')),
          );
        } else {
          final error = ref
              .read(condominiumDetailsControllerProvider(_scope))
              .actionError;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'Erro ao atualizar bloco.')),
          );
        }
        return ok;
      },
    );
  }

  Future<void> _openEditApartmentDialog(
    BlockModel block,
    ApartmentModel apartment,
  ) async {
    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );

    await showEditApartmentDialog(
      context: context,
      apartment: apartment,
      blockName: block.name,
      isDuplicateName: (candidate) => controller.hasApartmentInBlock(
        block.id,
        candidate,
        ignoreApartmentId: apartment.id,
      ),
      onSubmit: (name) async {
        final ok = await controller.updateApartment(
          blockId: block.id,
          apartment: apartment,
          name: name,
        );
        if (!mounted) return ok;

        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apartamento atualizado com sucesso.'),
            ),
          );
        } else {
          final error = ref
              .read(condominiumDetailsControllerProvider(_scope))
              .actionError;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'Erro ao atualizar apartamento.')),
          );
        }
        return ok;
      },
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _StepStatusChip extends StatelessWidget {
  final String label;
  final bool done;
  final VoidCallback? onTap;

  const _StepStatusChip({
    required this.label,
    required this.done,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 18,
        color: done ? colorScheme.primary : colorScheme.outline,
      ),
      label: Text(label),
      backgroundColor: done
          ? colorScheme.secondaryContainer.withValues(alpha: 0.5)
          : null,
      onPressed: onTap,
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final ApartmentWithBlockItem? linkedApartment;

  const _UserTile({
    required this.user,
    this.linkedApartment,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = user.name.trim().isNotEmpty
        ? user.name.trim().substring(0, 1).toUpperCase()
        : '?';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(child: Text(initial)),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email),
          if (linkedApartment != null)
            Text(
              '${linkedApartment!.block.name} • Apto ${linkedApartment!.apartment.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            label: Text(user.role.shortLabel),
            visualDensity: VisualDensity.compact,
            backgroundColor: user.isAdmin
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
          ),
          if (user.mustChangePassword)
            Chip(
              label: const Text('1º acesso pendente'),
              visualDensity: VisualDensity.compact,
              backgroundColor: colorScheme.tertiaryContainer,
            ),
          Chip(
            label: Text(user.active ? 'Ativo' : 'Inativo'),
            backgroundColor: user.active
                ? colorScheme.secondaryContainer
                : colorScheme.surfaceContainerHighest,
          ),
        ],
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

String _pluralWord(int count, String singular, String plural) {
  return count == 1 ? singular : plural;
}

String _pluralize(int count, String singular, String plural) {
  return '$count ${_pluralWord(count, singular, plural)}';
}
