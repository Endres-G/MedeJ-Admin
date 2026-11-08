import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mede_ja_admin/features/leituras/reading_datasrc.dart';
import 'package:mede_ja_admin/features/leituras/reading_model.dart';
import 'package:mede_ja_admin/features/leituras/readings_controller.dart';
import 'dart:html' as html;

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  DateTimeRange? _selectedDateRange;

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

        final overview = state.overview;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, overview, state.selectedMeterType),
              const SizedBox(height: 20),
              _buildMeterTypeSelector(context, state),
              const SizedBox(height: 20),
              _buildSelectors(context, state, isSmall),
              const SizedBox(height: 24),
              if (overview != null) ...[
                _buildReportSummary(context, overview, state.selectedMeterType),
                const SizedBox(height: 24),
                _buildActionToolbar(context, overview, state.selectedMeterType),
                const SizedBox(height: 16),
                _buildReportTable(context, overview, state.selectedMeterType),
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

  Widget _buildHeader(
    BuildContext context,
    CondominiumReadingsOverview? overview,
    MeterType meterType,
  ) {
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
                    'Relatórios de Medição',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Chip(
                    avatar: Icon(
                      meterType == MeterType.gas
                          ? Icons.local_fire_department_outlined
                          : Icons.water_drop_outlined,
                      size: 16,
                      color: meterType == MeterType.gas
                          ? Colors.deepOrange
                          : Colors.blue,
                    ),
                    label: Text(
                      meterType.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: meterType == MeterType.gas
                            ? Colors.deepOrange
                            : Colors.blue,
                      ),
                    ),
                    backgroundColor: meterType == MeterType.gas
                        ? Colors.deepOrange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Consolidação de dados de consumo de gás e água para rateio condominial e exportação de planilhas.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeterTypeSelector(BuildContext context, ReadingsState state) {
    return SegmentedButton<MeterType>(
      segments: const [
        ButtonSegment<MeterType>(
          value: MeterType.gas,
          icon: Icon(Icons.local_fire_department_outlined),
          label: Text('Relatório de Gás'),
        ),
        ButtonSegment<MeterType>(
          value: MeterType.water,
          icon: Icon(Icons.water_drop_outlined),
          label: Text('Relatório de Água'),
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

  Widget _buildReportSummary(
    BuildContext context,
    CondominiumReadingsOverview overview,
    MeterType meterType,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calcula totalizador de m³ lidos para o medidor ativo
    double totalM3 = 0.0;
    for (final apt in overview.apartments) {
      final val = apt.latestReadingFor(meterType)?.numericValue;
      if (val != null) totalM3 += val;
    }

    final measured = overview.measuredCount(meterType);
    final coverage = overview.coverageFor(meterType);

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  meterType == MeterType.gas
                      ? Icons.local_fire_department_outlined
                      : Icons.water_drop_outlined,
                  color: meterType == MeterType.gas ? Colors.deepOrange : Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Consolidação de ${meterType.label}: ${overview.condominiumName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                _SummaryLabel(
                  label: 'Administradora',
                  value: overview.administratorName,
                ),
                _SummaryLabel(
                  label: 'Total de Unidades',
                  value: '${overview.totalApartments}',
                ),
                _SummaryLabel(
                  label: 'Unidades Medidas (${meterType.label})',
                  value: '$measured (${(coverage * 100).toStringAsFixed(1)}%)',
                ),
                _SummaryLabel(
                  label: 'Soma dos Medidores (${meterType.label})',
                  value: '${totalM3.toStringAsFixed(3)} ${meterType.unit}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionToolbar(
    BuildContext context,
    CondominiumReadingsOverview overview,
    MeterType meterType,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Detalhamento por Unidade (${meterType.label})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.download),
          label: Text('Exportar Planilha de ${meterType.label} (CSV)'),
          onPressed: () => _exportCsv(overview, meterType),
        ),
      ],
    );
  }

  Widget _buildReportTable(
    BuildContext context,
    CondominiumReadingsOverview overview,
    MeterType meterType,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Bloco')),
            const DataColumn(label: Text('Unidade / Apartamento')),
            DataColumn(label: Text('Leitura de ${meterType.label} (${meterType.unit})')),
            const DataColumn(label: Text('Data da Leitura')),
            const DataColumn(label: Text('Status')),
          ],
          rows: overview.apartments.map((item) {
            final reading = item.latestReadingFor(meterType);
            final isDone = item.hasReadingFor(meterType);
            return DataRow(
              cells: [
                DataCell(Text(item.block.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('Apto ${item.apartment.name}')),
                DataCell(
                  Text(
                    reading != null ? '${reading.readingValue} ${meterType.unit}' : 'Pendente',
                    style: TextStyle(
                      fontWeight: reading != null ? FontWeight.bold : FontWeight.normal,
                      color: reading != null ? null : Colors.orange,
                    ),
                  ),
                ),
                DataCell(
                  Text(reading != null ? dateFormat.format(reading.readAt) : '—'),
                ),
                DataCell(
                  Text(
                    isDone ? 'Concluído' : 'Não Realizado',
                    style: TextStyle(
                      color: isDone ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
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
              Icon(Icons.description_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              const Text(
                'Selecione uma administradora e condomínio para gerar o relatório consolidado.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportCsv(CondominiumReadingsOverview overview, MeterType meterType) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final buffer = StringBuffer();

    // Cabeçalho CSV com Tipo de Medição
    buffer.writeln('Condominio;Administradora;Tipo_Medicao;Bloco;Apartamento;Leitura_m3;Data_Leitura;Status');

    for (final item in overview.apartments) {
      final reading = item.latestReadingFor(meterType);
      final val = reading != null ? reading.readingValue : '';
      final dt = reading != null ? dateFormat.format(reading.readAt) : '';
      final status = item.hasReadingFor(meterType) ? 'LIDO' : 'PENDENTE';

      buffer.writeln(
        '"${overview.condominiumName}";"${overview.administratorName}";"${meterType.label.toUpperCase()}";"${item.block.name}";"${item.apartment.name}";"$val";"$dt";"$status"',
      );
    }

    if (kIsWeb) {
      final bytes = utf8.encode('\uFEFF${buffer.toString()}'); // BOM UTF-8 para Excel
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'relatorio_leituras_${meterType.name}_${overview.condominiumName.toLowerCase().replaceAll(' ', '_')}.csv',
        )
        ..click();
      html.Url.revokeObjectUrl(url);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Planilha CSV de ${meterType.label} gerada e download iniciado com sucesso!'),
      ),
    );
  }
}

class _SummaryLabel extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
