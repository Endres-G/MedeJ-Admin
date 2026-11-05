import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/condominos/structure_dialogs.dart';

class ApartmentsPage extends ConsumerStatefulWidget {
  final String condominiumId;
  final String? administratorId;

  const ApartmentsPage({
    super.key,
    required this.condominiumId,
    this.administratorId,
  });

  @override
  ConsumerState<ApartmentsPage> createState() => _ApartmentsPageState();
}

class _ApartmentsPageState extends ConsumerState<ApartmentsPage> {
  String _selectedBlockId = 'Todos';
  String _statusFilter = 'Todos';
  String _search = '';

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

    final validBlockIds = <String>{
      'Todos',
      ...state.blocks.map((b) => b.block.id),
    };
    final effectiveBlockId = validBlockIds.contains(_selectedBlockId)
        ? _selectedBlockId
        : 'Todos';

    final query = _search.trim().toLowerCase();
    final allApartments = state.allApartments;

    final filteredApartments = allApartments.where((item) {
      final matchesBlock =
          effectiveBlockId == 'Todos' || item.block.id == effectiveBlockId;
      final matchesStatus =
          _statusFilter == 'Todos' ||
          (_statusFilter == 'Ativos' && item.apartment.active) ||
          (_statusFilter == 'Inativos' && !item.apartment.active);
      final matchesSearch =
          query.isEmpty ||
          item.apartment.name.toLowerCase().contains(query) ||
          item.block.name.toLowerCase().contains(query);

      return matchesBlock && matchesStatus && matchesSearch;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 760;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state, effectiveBlockId, isSmall),
              const SizedBox(height: 28),
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
              else ...[
                _buildSummary(context, state),
                const SizedBox(height: 28),
                if (state.blocks.isEmpty)
                  _buildNoBlocksCard(context, state)
                else if (allApartments.isEmpty)
                  _buildNoApartmentsCard(context, state, effectiveBlockId)
                else ...[
                  _buildFilters(context, state, effectiveBlockId, isSmall),
                  const SizedBox(height: 16),
                  _buildApartmentsList(context, state, filteredApartments),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CondominiumDetailsState state,
    String effectiveBlockId,
    bool isSmall,
  ) {
    final adminId = _effectiveAdminId(state);

    final ctaButton = state.blocks.isEmpty
        ? FilledButton.icon(
            onPressed: () => context.go(
              AppRoutes.newBlockPath(
                widget.condominiumId,
                administratorId: adminId,
              ),
            ),
            icon: const Icon(Icons.domain_add_outlined),
            label: const Text('Criar bloco primeiro'),
          )
        : FilledButton.icon(
            onPressed: () => context.go(
              AppRoutes.newApartmentPath(
                widget.condominiumId,
                administratorId: adminId,
                blockId: effectiveBlockId == 'Todos' ? null : effectiveBlockId,
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Novo apartamento'),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              label: const Text('Condomínio'),
            ),
            IconButton(
              tooltip: 'Atualizar apartamentos',
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
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apartamentos',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (state.condominium != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      state.condominium!.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
            ),
            if (!isSmall) ctaButton,
          ],
        ),
        if (isSmall) ...[
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ctaButton),
        ],
      ],
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
                title: 'Total de apartamentos',
                value: '${state.totalApartments}',
                icon: Icons.home_work_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Ativos',
                value: '${state.activeApartments}',
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Inativos',
                value: '${state.inactiveApartments}',
                icon: Icons.pause_circle_outline,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoBlocksCard(
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
                Icons.domain_disabled_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Cadastre ao menos um bloco primeiro.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Todo apartamento deve pertencer a um bloco do condomínio.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go(
                  AppRoutes.newBlockPath(
                    widget.condominiumId,
                    administratorId: adminId,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Criar bloco'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoApartmentsCard(
    BuildContext context,
    CondominiumDetailsState state,
    String effectiveBlockId,
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
                Icons.home_work_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhum apartamento cadastrado ainda.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cadastre apartamentos individualmente ou gere vários andares em lote.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go(
                  AppRoutes.newApartmentPath(
                    widget.condominiumId,
                    administratorId: adminId,
                    blockId: effectiveBlockId == 'Todos'
                        ? null
                        : effectiveBlockId,
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Cadastrar apartamentos'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    CondominiumDetailsState state,
    String effectiveBlockId,
    bool isSmall,
  ) {
    final searchField = TextField(
      decoration: InputDecoration(
        labelText: 'Buscar apartamento ou bloco',
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
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
    );

    final blockDropdown = DropdownButtonFormField<String>(
      key: ValueKey(effectiveBlockId),
      initialValue: effectiveBlockId,
      decoration: const InputDecoration(
        labelText: 'Bloco',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: 'Todos', child: Text('Todos os blocos')),
        ...state.blocks.map(
          (b) => DropdownMenuItem(
            value: b.block.id,
            child: Text(b.block.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedBlockId = value;
        });
      },
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

    if (isSmall) {
      return Column(
        children: [
          searchField,
          const SizedBox(height: 12),
          blockDropdown,
          const SizedBox(height: 12),
          statusDropdown,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 16),
        SizedBox(width: 240, child: blockDropdown),
        const SizedBox(width: 16),
        SizedBox(width: 180, child: statusDropdown),
      ],
    );
  }

  Widget _buildApartmentsList(
    BuildContext context,
    CondominiumDetailsState state,
    List<ApartmentWithBlockItem> items,
  ) {
    final adminId = _effectiveAdminId(state);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Nenhum apartamento encontrado para os filtros selecionados.'),
              ),
            )
          : Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Column(
                  children: [
                    _ApartmentListTile(
                      item: item,
                      isBusy: state.isSaving,
                      onEdit: () => _editApartment(item.block, item.apartment),
                      onToggleActive: () =>
                          _toggleApartment(item.block, item.apartment),
                      onOpenBlock: () => context.go(
                        AppRoutes.blockDetailsPath(
                          widget.condominiumId,
                          item.block.id,
                          administratorId: adminId,
                        ),
                      ),
                    ),
                    if (index < items.length - 1) const Divider(height: 1),
                  ],
                );
              }),
            ),
    );
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

class _ApartmentListTile extends StatelessWidget {
  final ApartmentWithBlockItem item;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onOpenBlock;

  const _ApartmentListTile({
    required this.item,
    required this.isBusy,
    required this.onEdit,
    required this.onToggleActive,
    required this.onOpenBlock,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final apartment = item.apartment;

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
        child: Text(item.block.name),
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
          FilledButton.tonal(
            onPressed: onOpenBlock,
            child: const Text('Ver bloco'),
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
