import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/condominos/structure_dialogs.dart';

class BlockDetailsPage extends ConsumerStatefulWidget {
  final String condominiumId;
  final String blockId;
  final String? administratorId;

  const BlockDetailsPage({
    super.key,
    required this.condominiumId,
    required this.blockId,
    this.administratorId,
  });

  @override
  ConsumerState<BlockDetailsPage> createState() => _BlockDetailsPageState();
}

class _BlockDetailsPageState extends ConsumerState<BlockDetailsPage> {
  String _search = '';
  String _statusFilter = 'Todos';

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
    final blockItem = state.findBlock(widget.blockId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 720;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, state),
              const SizedBox(height: 20),
              if (state.isLoading && state.condominium == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (state.error != null && state.condominium == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(state.error!)),
                  ),
                )
              else if (blockItem == null)
                _buildNotFoundCard(context, state)
              else ...[
                _buildHeader(context, state, blockItem, isSmall),
                const SizedBox(height: 28),
                _buildSummary(context, blockItem),
                const SizedBox(height: 28),
                _buildApartments(context, state, blockItem, isSmall),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, CondominiumDetailsState state) {
    final adminId = _effectiveAdminId(state);
    final condoName = state.condominium?.name.trim() ?? '';
    final backToCondoLabel = condoName.isNotEmpty
        ? 'Voltar para $condoName'
        : 'Voltar para Condomínio';
    final allBlocksLabel = condoName.isNotEmpty
        ? 'Blocos de $condoName'
        : 'Todos os blocos';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: () {
                  context.go(
                    AppRoutes.condominiumDetailsPath(
                      widget.condominiumId,
                      administratorId: adminId,
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(backToCondoLabel),
              ),
              TextButton.icon(
                onPressed: () {
                  context.go(
                    AppRoutes.condominiumBlocksPath(
                      widget.condominiumId,
                      administratorId: adminId,
                    ),
                  );
                },
                icon: const Icon(Icons.domain_outlined),
                label: Text(allBlocksLabel),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Atualizar',
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

  Widget _buildNotFoundCard(
    BuildContext context,
    CondominiumDetailsState state,
  ) {
    final adminId = _effectiveAdminId(state);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              const Text('Bloco não encontrado neste condomínio.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(
                  AppRoutes.condominiumBlocksPath(
                    widget.condominiumId,
                    administratorId: adminId,
                  ),
                ),
                child: const Text('Voltar para blocos'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CondominiumDetailsState state,
    BlockOverviewItem blockItem,
    bool isSmall,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final block = blockItem.block;
    final adminId = _effectiveAdminId(state);

    final info = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          child: Icon(
            Icons.domain_outlined,
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
                block.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.condominium != null) ...[
                const SizedBox(height: 4),
                Text(
                  state.condominium!.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: 8),
              Chip(
                label: Text(block.active ? 'Ativo' : 'Inativo'),
                backgroundColor: block.active
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest,
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
          onPressed: state.isSaving ? null : () => _editBlock(block),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
        ),
        OutlinedButton.icon(
          onPressed: state.isSaving ? null : () => _toggleBlock(block),
          icon: Icon(
            block.active
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
          ),
          label: Text(block.active ? 'Desativar' : 'Ativar'),
        ),
        FilledButton.icon(
          onPressed: () => context.go(
            AppRoutes.newApartmentPath(
              widget.condominiumId,
              administratorId: adminId,
              blockId: block.id,
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar apartamentos'),
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

  Widget _buildSummary(BuildContext context, BlockOverviewItem blockItem) {
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
                title: 'Total de apartamentos',
                value: '${blockItem.totalApartments}',
                icon: Icons.home_work_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Ativos',
                value: '${blockItem.activeApartments}',
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Inativos',
                value: '${blockItem.inactiveApartments}',
                icon: Icons.pause_circle_outline,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildApartments(
    BuildContext context,
    CondominiumDetailsState state,
    BlockOverviewItem blockItem,
    bool isSmall,
  ) {
    final adminId = _effectiveAdminId(state);
    final newApartmentRoute = AppRoutes.newApartmentPath(
      widget.condominiumId,
      administratorId: adminId,
      blockId: blockItem.block.id,
    );

    if (blockItem.apartments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhum apartamento cadastrado em ${blockItem.block.name}.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Adicione um apartamento individualmente ou gere todos os andares em lote.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.go(newApartmentRoute),
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Cadastrar apartamentos'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final query = _search.trim().toLowerCase();
    final filtered = blockItem.apartments.where((apartment) {
      final matchesSearch =
          query.isEmpty || apartment.name.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'Todos' ||
          (_statusFilter == 'Ativos' && apartment.active) ||
          (_statusFilter == 'Inativos' && !apartment.active);
      return matchesSearch && matchesStatus;
    }).toList();

    final searchField = TextField(
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      decoration: InputDecoration(
        labelText: 'Buscar apartamento',
        hintText: 'Ex.: 101',
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
      key: ValueKey(_statusFilter),
      initialValue: _statusFilter,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Todos', child: Text('Todos')),
        DropdownMenuItem(value: 'Ativos', child: Text('Ativos')),
        DropdownMenuItem(value: 'Inativos', child: Text('Inativos')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _statusFilter = value;
        });
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apartamentos do bloco',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (isSmall) ...[
          searchField,
          const SizedBox(height: 12),
          statusDropdown,
        ] else
          Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 16),
              SizedBox(width: 220, child: statusDropdown),
            ],
          ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Nenhum apartamento encontrado para este filtro.'),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(filtered.length, (index) {
                final apartment = filtered[index];
                return Column(
                  children: [
                    _ApartmentTile(
                      apartment: apartment,
                      blockName: blockItem.block.name,
                      isBusy: state.isSaving,
                      onEdit: () =>
                          _editApartment(blockItem.block, apartment),
                      onToggleActive: () =>
                          _toggleApartment(blockItem.block, apartment),
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

  Future<void> _editBlock(BlockModel block) async {
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
        }
        return ok;
      },
    );
  }

  Future<void> _toggleBlock(BlockModel block) async {
    final confirmed = await showConfirmStatusToggleDialog(
      context: context,
      entityLabel: 'bloco',
      entityName: block.name,
      currentlyActive: block.active,
    );
    if (!confirmed || !mounted) return;

    final ok = await ref
        .read(condominiumDetailsControllerProvider(_scope).notifier)
        .toggleBlockActive(block);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            block.active
                ? 'Bloco desativado com sucesso.'
                : 'Bloco reativado com sucesso.',
          ),
        ),
      );
    }
  }

  Future<void> _editApartment(
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
        }
        return ok;
      },
    );
  }

  Future<void> _toggleApartment(
    BlockModel block,
    ApartmentModel apartment,
  ) async {
    final ok = await ref
        .read(condominiumDetailsControllerProvider(_scope).notifier)
        .toggleApartmentActive(blockId: block.id, apartment: apartment);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            apartment.active
                ? 'Apartamento ${apartment.name} desativado.'
                : 'Apartamento ${apartment.name} reativado.',
          ),
        ),
      );
    }
  }
}

class _ApartmentTile extends StatelessWidget {
  final ApartmentModel apartment;
  final String blockName;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _ApartmentTile({
    required this.apartment,
    required this.blockName,
    required this.isBusy,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: CircleAvatar(
        child: Icon(Icons.home_work_outlined, color: colorScheme.primary),
      ),
      title: Text(
        'Apartamento ${apartment.name}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(blockName),
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            label: Text(apartment.active ? 'Ativo' : 'Inativo'),
            backgroundColor: apartment.active
                ? colorScheme.secondaryContainer
                : colorScheme.surfaceContainerHighest,
          ),
          IconButton(
            tooltip: 'Editar apartamento',
            onPressed: isBusy ? null : onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: apartment.active ? 'Desativar' : 'Ativar',
            onPressed: isBusy ? null : onToggleActive,
            icon: Icon(
              apartment.active
                  ? Icons.toggle_on_outlined
                  : Icons.toggle_off_outlined,
            ),
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

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
