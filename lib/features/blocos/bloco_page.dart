import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/condominos/structure_dialogs.dart';

class BlocksPage extends ConsumerStatefulWidget {
  final String condominiumId;
  final String? administratorId;

  const BlocksPage({
    super.key,
    required this.condominiumId,
    this.administratorId,
  });

  @override
  ConsumerState<BlocksPage> createState() => _BlocksPageState();
}

class _BlocksPageState extends ConsumerState<BlocksPage> {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 740;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state, isSmall),
              const SizedBox(height: 28),
              if (state.isLoading && state.condominium == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (state.error != null && state.condominium == null)
                _buildErrorCard(context, state.error!)
              else ...[
                _buildSummary(context, state),
                const SizedBox(height: 28),
                _buildBlocksList(context, state, isSmall),
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
    bool isSmall,
  ) {
    final adminId = _effectiveAdminId(state);

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
              tooltip: 'Atualizar blocos',
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
                    'Blocos',
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
            if (!isSmall)
              Wrap(
                spacing: 10,
                children: [
                  if (state.totalBlocks > 0)
                    FilledButton.tonalIcon(
                      onPressed: () => context.go(
                        AppRoutes.newApartmentPath(
                          widget.condominiumId,
                          administratorId: adminId,
                        ),
                      ),
                      icon: const Icon(Icons.add_home_work_outlined),
                      label: const Text('Novo apartamento'),
                    ),
                  FilledButton.icon(
                    onPressed: () => _openNewBlock(context, adminId),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo bloco'),
                  ),
                ],
              ),
          ],
        ),
        if (isSmall) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => _openNewBlock(context, adminId),
                icon: const Icon(Icons.add),
                label: const Text('Novo bloco'),
              ),
              if (state.totalBlocks > 0)
                FilledButton.tonalIcon(
                  onPressed: () => context.go(
                    AppRoutes.newApartmentPath(
                      widget.condominiumId,
                      administratorId: adminId,
                    ),
                  ),
                  icon: const Icon(Icons.add_home_work_outlined),
                  label: const Text('Novo apartamento'),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Card(
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
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
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
    );
  }

  Widget _buildSummary(BuildContext context, CondominiumDetailsState state) {
    final avgText = state.totalBlocks == 0
        ? '0'
        : (state.totalApartments / state.totalBlocks)
              .toStringAsFixed(1)
              .replaceAll('.0', '');

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
                subtitle: '${state.activeBlocks} ativos',
                icon: Icons.domain_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Apartamentos',
                value: '${state.totalApartments}',
                subtitle: '${state.activeApartments} ativos',
                icon: Icons.home_work_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Média por bloco',
                value: avgText,
                subtitle: 'apartamentos por bloco',
                icon: Icons.analytics_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlocksList(
    BuildContext context,
    CondominiumDetailsState state,
    bool isSmall,
  ) {
    final adminId = _effectiveAdminId(state);

    if (state.blocks.isEmpty) {
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
                  'Nenhum bloco cadastrado neste condomínio.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Crie os blocos do empreendimento (individualmente ou em lote) para em seguida vincular os apartamentos.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openNewBlock(context, adminId),
                  icon: const Icon(Icons.add),
                  label: const Text('Criar primeiro bloco'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final query = _search.trim().toLowerCase();
    final filtered = state.blocks.where((item) {
      if (query.isEmpty) return true;
      return item.block.name.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blocos cadastrados',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (value) {
            setState(() {
              _search = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Buscar bloco pelo nome...',
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
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Nenhum bloco encontrado.')),
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
                    _BlockTile(
                      item: item,
                      isSmall: isSmall,
                      isBusy: state.isSaving,
                      onEdit: () => _editBlock(item.block),
                      onToggleActive: () => _toggleBlock(item.block),
                      onAddApartments: () => context.go(
                        AppRoutes.newApartmentPath(
                          widget.condominiumId,
                          administratorId: adminId,
                          blockId: item.block.id,
                        ),
                      ),
                      onOpen: () => _openBlock(context, item.block.id, adminId),
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

  void _openNewBlock(BuildContext context, String? adminId) {
    context.go(
      AppRoutes.newBlockPath(widget.condominiumId, administratorId: adminId),
    );
  }

  void _openBlock(BuildContext context, String blockId, String? adminId) {
    context.go(
      AppRoutes.blockDetailsPath(
        widget.condominiumId,
        blockId,
        administratorId: adminId,
      ),
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
}

class _BlockTile extends StatelessWidget {
  final BlockOverviewItem item;
  final bool isSmall;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onAddApartments;
  final VoidCallback onOpen;

  const _BlockTile({
    required this.item,
    required this.isSmall,
    required this.isBusy,
    required this.onEdit,
    required this.onToggleActive,
    required this.onAddApartments,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final block = item.block;
    final countText = item.totalApartments == 0
        ? 'Nenhum apartamento cadastrado'
        : '${item.totalApartments} ${item.totalApartments == 1 ? 'apartamento' : 'apartamentos'} (${item.activeApartments} ${item.activeApartments == 1 ? 'ativo' : 'ativos'})';

    final trailingActions = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Chip(
          label: Text(block.active ? 'Ativo' : 'Inativo'),
          backgroundColor: block.active
              ? colorScheme.secondaryContainer
              : colorScheme.surfaceContainerHighest,
        ),
        IconButton(
          tooltip: 'Editar bloco',
          onPressed: isBusy ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: block.active ? 'Desativar bloco' : 'Ativar bloco',
          onPressed: isBusy ? null : onToggleActive,
          icon: Icon(
            block.active
                ? Icons.toggle_on_outlined
                : Icons.toggle_off_outlined,
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAddApartments,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Apartamentos'),
        ),
        FilledButton.tonal(onPressed: onOpen, child: const Text('Abrir')),
      ],
    );

    if (isSmall) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.domain_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        countText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            trailingActions,
          ],
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: CircleAvatar(
        child: Icon(Icons.domain_outlined, color: colorScheme.primary),
      ),
      title: Text(
        block.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(countText),
      ),
      trailing: trailingActions,
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
