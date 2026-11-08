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
              const SizedBox(height: 20),
              _buildControlsBar(context, state, isSmall),
              const SizedBox(height: 20),
              _buildSelectors(context, state, isSmall),
              const SizedBox(height: 24),
              if (state.overview != null) ...[
                _buildSummaryCards(context, state.overview!, state.selectedMeterType, state.currentMonth),
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
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    'Leituras de Medição',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Chip(
                    avatar: Icon(
                      state.selectedMeterType == MeterType.gas
                          ? Icons.local_fire_department_outlined
                          : Icons.water_drop_outlined,
                      size: 16,
                      color: state.selectedMeterType == MeterType.gas
                          ? Colors.deepOrange
                          : Colors.blue,
                    ),
                    label: Text(
                      state.selectedMeterType.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: state.selectedMeterType == MeterType.gas
                            ? Colors.deepOrange
                            : Colors.blue,
                      ),
                    ),
                    backgroundColor: state.selectedMeterType == MeterType.gas
                        ? Colors.deepOrange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  ),
                  Chip(
                    avatar: const Icon(Icons.calendar_today_outlined, size: 14),
                    label: Text(
                      'Competência: ${_formatMonthYear(state.currentMonth)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Acompanhamento em tempo real dos registros de medição e apuração de consumo por competência.',
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

  Widget _buildControlsBar(BuildContext context, ReadingsState state, bool isSmall) {
    final meterSelector = _buildMeterTypeSelector(context, state);
    final monthSelector = _buildMonthSelector(context, state);

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          meterSelector,
          const SizedBox(height: 12),
          monthSelector,
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        meterSelector,
        monthSelector,
      ],
    );
  }

  Widget _buildMeterTypeSelector(BuildContext context, ReadingsState state) {
    return SegmentedButton<MeterType>(
      segments: const [
        ButtonSegment<MeterType>(
          value: MeterType.gas,
          icon: Icon(Icons.local_fire_department_outlined),
          label: Text('Medidor de Gás'),
        ),
        ButtonSegment<MeterType>(
          value: MeterType.water,
          icon: Icon(Icons.water_drop_outlined),
          label: Text('Medidor de Água'),
        ),
      ],
      selected: {state.selectedMeterType},
      onSelectionChanged: (selectedSet) {
        if (selectedSet.isNotEmpty) {
          ref.read(readingsControllerProvider.notifier).setMeterType(selectedSet.first);
        }
      },
    );
  }

  Widget _buildMonthSelector(BuildContext context, ReadingsState state) {
    final month = state.currentMonth;
    final isCurrentMonth = month.year == DateTime.now().year &&
        month.month == DateTime.now().month;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mês anterior',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                ref.read(readingsControllerProvider.notifier).previousMonth(),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.calendar_month_outlined, size: 18),
          const SizedBox(width: 8),
          Text(
            _formatMonthYear(month),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próximo mês',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                ref.read(readingsControllerProvider.notifier).nextMonth(),
          ),
          if (!isCurrentMonth) ...[
            const SizedBox(width: 4),
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => ref
                  .read(readingsControllerProvider.notifier)
                  .setMonth(DateTime.now()),
              child: const Text('Mês atual'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${months[dt.month - 1]} / ${dt.year}';
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
    MeterType meterType,
    DateTime month,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final measured = overview.measuredCount(meterType);
    final pending = overview.pendingCount(meterType);
    final coverage = overview.coverageFor(meterType);
    final latestDate = overview.latestDateFor(meterType);
    final isGas = meterType == MeterType.gas;
    final monthName = _formatMonthYear(month);

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
                title: 'Medições em $monthName',
                value: '$measured',
                subtitle: '${(coverage * 100).toStringAsFixed(1)}% do condomínio',
                icon: isGas ? Icons.local_fire_department_outlined : Icons.water_drop_outlined,
                color: isGas ? Colors.deepOrange : Colors.blue,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Pendentes no Mês',
                value: '$pending',
                subtitle: 'Aguardando registro em $monthName',
                icon: Icons.pending_outlined,
                color: pending > 0 ? Colors.orange : Colors.grey,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Última Transmissão',
                value: latestDate != null
                    ? dateFormat.format(latestDate)
                    : 'Nenhuma no mês',
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
    final meterType = state.selectedMeterType;

    final filtered = overview.apartments.where((item) {
      if (_selectedBlockFilter != null && item.block.name != _selectedBlockFilter) {
        return false;
      }
      final hasReading = item.hasReadingFor(meterType);
      if (_statusFilter == 'Lidos' && !hasReading) return false;
      if (_statusFilter == 'Pendentes' && hasReading) return false;

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
          columns: [
            const DataColumn(label: Text('Bloco')),
            const DataColumn(label: Text('Apartamento')),
            const DataColumn(label: Text('Status no Mês')),
            DataColumn(label: Text('Leitura Anterior (${meterType.unit})')),
            DataColumn(label: Text('Leitura do Mês (${meterType.unit})')),
            DataColumn(label: Text('Consumo no Mês (${meterType.unit})')),
            const DataColumn(label: Text('Data da Leitura')),
            const DataColumn(label: Text('Foto')),
            const DataColumn(label: Text('Ações')),
          ],
          rows: filtered.map((item) {
            final reading = item.latestReadingFor(meterType);
            final prevReading = item.previousReadingFor(meterType);
            final consumption = item.consumptionFor(meterType);
            final isDone = item.hasReadingFor(meterType);

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
                    prevReading != null ? '${prevReading.readingValue} ${meterType.unit}' : '—',
                    style: TextStyle(
                      color: prevReading != null ? colorScheme.onSurfaceVariant : colorScheme.outline,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    reading != null ? '${reading.readingValue} ${meterType.unit}' : 'Pendente',
                    style: TextStyle(
                      fontWeight: reading != null ? FontWeight.bold : FontWeight.normal,
                      color: reading != null ? null : Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ),
                DataCell(
                  consumption != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${consumption.toStringAsFixed(3)} ${meterType.unit}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        )
                      : Text(
                          reading != null && prevReading == null ? 'Sem anterior' : '—',
                          style: TextStyle(color: colorScheme.outline, fontSize: 13),
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
          height: history.isEmpty ? 120 : 360,
          child: history.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Nenhuma leitura registrada no histórico.')),
                )
              : ListView.separated(
                  shrinkWrap: false,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, index) {
                    final h = history[index];
                    final isGas = h.meterType == MeterType.gas;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isGas
                            ? Colors.deepOrange.withValues(alpha: 0.15)
                            : Colors.blue.withValues(alpha: 0.15),
                        child: Icon(
                          isGas
                              ? Icons.local_fire_department_outlined
                              : Icons.water_drop_outlined,
                          color: isGas ? Colors.deepOrange : Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            '${h.readingValue} ${h.meterType.unit}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isGas
                                  ? Colors.deepOrange.withValues(alpha: 0.12)
                                  : Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              h.meterType.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isGas ? Colors.deepOrange : Colors.blue,
                              ),
                            ),
                          ),
                        ],
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
