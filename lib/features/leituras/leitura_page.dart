import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mede_ja_admin/features/leituras/reading_datasrc.dart';
import 'package:mede_ja_admin/features/leituras/reading_model.dart';
import 'package:mede_ja_admin/features/leituras/readings_controller.dart';

class ReadingsPage extends ConsumerStatefulWidget {
  const ReadingsPage({super.key});

  @override
  ConsumerState<ReadingsPage> createState() => _ReadingsPageState();
}

class _ReadingsPageState extends ConsumerState<ReadingsPage> {
  final _searchController = TextEditingController();
  String _search = '';
  String _statusFilter = 'Todos'; // 'Todos', 'Lidos', 'Pendentes'
  String? _selectedBlockFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readingsControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

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

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state, isSmall),
              const SizedBox(height: 24),
              _buildSelectors(context, state, isSmall),
              const SizedBox(height: 24),
              if (state.overview != null) ...[
                _buildSummaryCards(context, state.overview!),
                const SizedBox(height: 24),
                _buildFilters(context, state.overview!, isSmall),
                const SizedBox(height: 16),
                _buildReadingsTable(context, state, colorScheme),
              ] else if (state.isLoadingReadings) ...[
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ] else ...[
                _buildEmptyState(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ReadingsState state, bool isSmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leituras de Gás',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Acompanhamento em tempo real dos registros de medição enviados pelo aplicativo móvel.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Atualizar leituras',
          onPressed: () => ref.read(readingsControllerProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildSelectors(
    BuildContext context,
    ReadingsState state,
    bool isSmall,
  ) {
    final adminItems = state.administrators.map((admin) {
      return DropdownMenuItem(
        value: admin.id,
        child: Text(admin.name, overflow: TextOverflow.ellipsis),
      );
    }).toList();

    final condoItems = state.condominiums.map((condo) {
      return DropdownMenuItem(
        value: condo.id,
        child: Text(condo.name, overflow: TextOverflow.ellipsis),
      );
    }).toList();

    final adminSelector = DropdownButtonFormField<String>(
      value: state.selectedAdministratorId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Administradora',
        prefixIcon: Icon(Icons.business_outlined),
        border: OutlineInputBorder(),
      ),
      items: adminItems,
      onChanged: (id) {
        if (id != null) {
          ref.read(readingsControllerProvider.notifier).selectAdministrator(id);
        }
      },
    );

    final condoSelector = DropdownButtonFormField<String>(
      value: state.selectedCondominiumId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Condomínio',
        prefixIcon: Icon(Icons.apartment_outlined),
        border: OutlineInputBorder(),
      ),
      items: condoItems,
      onChanged: (id) {
        if (id != null) {
          ref.read(readingsControllerProvider.notifier).selectCondominium(id);
        }
      },
    );

    if (isSmall) {
      return Column(
        children: [
          adminSelector,
          const SizedBox(height: 16),
          condoSelector,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: adminSelector),
        const SizedBox(width: 16),
        Expanded(child: condoSelector),
      ],
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    CondominiumReadingsOverview overview,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        final cardWidth = isNarrow
            ? constraints.maxWidth
            : (constraints.maxWidth - (3 * 16)) / 4;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Total de Unidades',
                value: '${overview.totalApartments}',
                subtitle: 'Apartamentos cadastrados',
                icon: Icons.home_work_outlined,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Medições Realizadas',
                value: '${overview.measuredApartments}',
                subtitle: '${(overview.coveragePercentage * 100).toStringAsFixed(1)}% do condomínio',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Leituras Pendentes',
                value: '${overview.pendingApartments}',
                subtitle: 'Aguardando registro',
                icon: Icons.pending_outlined,
                color: overview.pendingApartments > 0 ? Colors.orange : Colors.grey,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Última Transmissão',
                value: overview.latestGlobalReadingDate != null
                    ? dateFormat.format(overview.latestGlobalReadingDate!)
                    : 'Nenhuma',
                subtitle: 'Sincronizado via mobile',
                icon: Icons.cloud_done_outlined,
                color: colorScheme.secondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(
    BuildContext context,
    CondominiumReadingsOverview overview,
    bool isSmall,
  ) {
    final blocks = overview.apartments.map((a) => a.block.name).toSet().toList()..sort();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar por apartamento...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _search = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _search = v.trim()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedBlockFilter,
            decoration: const InputDecoration(
              labelText: 'Filtrar por Bloco',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos os Blocos')),
              ...blocks.map((b) => DropdownMenuItem(value: b, child: Text(b))),
            ],
            onChanged: (v) => setState(() => _selectedBlockFilter = v),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: const InputDecoration(
              labelText: 'Status da Leitura',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Todos', child: Text('Todos')),
              DropdownMenuItem(value: 'Lidos', child: Text('Apenas Lidos')),
              DropdownMenuItem(value: 'Pendentes', child: Text('Apenas Pendentes')),
            ],
            onChanged: (v) => setState(() => _statusFilter = v ?? 'Todos'),
          ),
        ),
      ],
    );
  }

  Widget _buildReadingsTable(
    BuildContext context,
    ReadingsState state,
    ColorScheme colorScheme,
  ) {
    final overview = state.overview!;
    final query = _search.toLowerCase();

    final filtered = overview.apartments.where((item) {
      if (_selectedBlockFilter != null && item.block.name != _selectedBlockFilter) {
        return false;
      }
      if (_statusFilter == 'Lidos' && !item.hasReading) return false;
      if (_statusFilter == 'Pendentes' && item.hasReading) return false;

      if (query.isNotEmpty) {
        final matchApt = item.apartment.name.toLowerCase().contains(query);
        final matchBlock = item.block.name.toLowerCase().contains(query);
        return matchApt || matchBlock;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: colorScheme.outline),
                const SizedBox(height: 12),
                const Text('Nenhum apartamento encontrado com os filtros aplicados.'),
              ],
            ),
          ),
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Bloco')),
            DataColumn(label: Text('Apartamento')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Valor da Leitura (m³)')),
            DataColumn(label: Text('Data / Hora')),
            DataColumn(label: Text('Foto')),
            DataColumn(label: Text('Ações')),
          ],
          rows: filtered.map((item) {
            final reading = item.latestReading;
            final isDone = item.hasReading;

            return DataRow(
              cells: [
                DataCell(Text(item.block.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(item.apartment.name)),
                DataCell(
                  Chip(
                    avatar: Icon(
                      isDone ? Icons.check : Icons.access_time,
                      size: 14,
                      color: isDone ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                    label: Text(
                      isDone ? 'Concluído' : 'Pendente',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDone ? Colors.green.shade800 : Colors.orange.shade800,
                      ),
                    ),
                    backgroundColor: isDone ? Colors.green.shade50 : Colors.orange.shade50,
                  ),
                ),
                DataCell(
                  Text(
                    reading != null ? '${reading.readingValue} m³' : '—',
                    style: TextStyle(
                      fontWeight: reading != null ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
                DataCell(
                  Text(reading != null ? dateFormat.format(reading.readAt) : '—'),
                ),
                DataCell(
                  reading?.photoUrl != null
                      ? IconButton(
                          icon: const Icon(Icons.image, color: Colors.blue),
                          tooltip: 'Visualizar foto do medidor',
                          onPressed: () => _showPhotoDialog(context, reading!.photoUrl!),
                        )
                      : Text(
                          reading?.photoPath != null ? 'Salvo no aparelho' : '—',
                          style: TextStyle(color: colorScheme.outline, fontSize: 12),
                        ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: 'Ver histórico deste apartamento',
                    onPressed: () => _showHistoryDialog(context, item),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.speed_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              const Text(
                'Selecione uma administradora e condomínio para visualizar as medições.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Foto do Medidor'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Image.network(
                url,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : const CircularProgressIndicator(),
                errorBuilder: (_, __, ___) => const Text('Não foi possível carregar a imagem.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, ApartmentReadingItem item) async {
    final controller = ref.read(readingsControllerProvider.notifier);
    final history = await controller.loadApartmentHistory(
      blockId: item.block.id,
      apartmentId: item.apartment.id,
    );

    if (!mounted) return;

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Histórico: ${item.block.name} - Apto ${item.apartment.name}'),
        content: SizedBox(
          width: 500,
          child: history.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Nenhuma leitura registrada no histórico.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, index) {
                    final h = history[index];
                    return ListTile(
                      leading: const Icon(Icons.gas_meter_outlined),
                      title: Text(
                        '${h.readingValue} m³',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Data: ${dateFormat.format(h.readAt)}'),
                      trailing: h.photoUrl != null
                          ? IconButton(
                              icon: const Icon(Icons.image_outlined),
                              onPressed: () => _showPhotoDialog(dialogCtx, h.photoUrl!),
                            )
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
