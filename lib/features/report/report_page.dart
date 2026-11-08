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
              _buildHeader(context, overview, state.selectedMeterType, state.currentMonth),
              const SizedBox(height: 20),
              _buildControlsBar(context, state, isSmall),
              const SizedBox(height: 20),
              _buildSelectors(context, state, isSmall),
              const SizedBox(height: 24),
              if (overview != null) ...[
                _buildReportSummary(context, overview, state.selectedMeterType, state.currentMonth),
                const SizedBox(height: 24),
                _buildActionToolbar(context, overview, state.selectedMeterType, state.currentMonth),
                const SizedBox(height: 16),
                _buildReportTable(context, overview, state.selectedMeterType),
                const SizedBox(height: 28),
                _buildExportPackagesSection(context, overview, state.selectedMeterType, state.currentMonth),
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
    DateTime month,
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
                  Chip(
                    avatar: const Icon(Icons.calendar_today_outlined, size: 14),
                    label: Text(
                      'Competência: ${_formatMonthYear(month)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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

  Widget _buildReportSummary(
    BuildContext context,
    CondominiumReadingsOverview overview,
    MeterType meterType,
    DateTime month,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calcula totalizador de consumo apurado no mês
    double totalConsumptionM3 = 0.0;
    for (final apt in overview.apartments) {
      final val = apt.consumptionFor(meterType);
      if (val != null) totalConsumptionM3 += val;
    }

    final measured = overview.measuredCount(meterType);
    final coverage = overview.coverageFor(meterType);
    final monthName = _formatMonthYear(month);

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
                    'Consolidação de ${meterType.label} - $monthName: ${overview.condominiumName}',
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
                  label: 'Competência',
                  value: monthName,
                ),
                _SummaryLabel(
                  label: 'Total de Unidades',
                  value: '${overview.totalApartments}',
                ),
                _SummaryLabel(
                  label: 'Medidas no Mês (${meterType.label})',
                  value: '$measured (${(coverage * 100).toStringAsFixed(1)}%)',
                ),
                _SummaryLabel(
                  label: 'Soma de Consumo no Mês',
                  value: '${totalConsumptionM3.toStringAsFixed(3)} ${meterType.unit}',
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
    DateTime month,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Detalhamento por Unidade (${meterType.label} - ${_formatMonthYear(month)})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.download),
          label: Text('Exportar Planilha de ${meterType.label} (CSV)'),
          onPressed: () => _exportCsv(overview, meterType, month),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Bloco')),
            const DataColumn(label: Text('Unidade / Apartamento')),
            const DataColumn(label: Text('Status no Mês')),
            DataColumn(label: Text('Leitura Anterior (${meterType.unit})')),
            DataColumn(label: Text('Leitura do Mês (${meterType.unit})')),
            DataColumn(label: Text('Consumo no Mês (${meterType.unit})')),
            const DataColumn(label: Text('Foto / Medidor')),
            const DataColumn(label: Text('Data da Leitura')),
          ],
          rows: overview.apartments.map((item) {
            final reading = item.latestReadingFor(meterType);
            final prev = item.previousReadingFor(meterType);
            final consumption = item.consumptionFor(meterType);
            final isDone = item.hasReadingFor(meterType);

            return DataRow(
              cells: [
                DataCell(Text(item.block.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('Apto ${item.apartment.name}')),
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
                    prev != null ? '${prev.readingValue} ${meterType.unit}' : '—',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                ),
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
                          reading != null && prev == null ? 'Sem anterior' : '—',
                          style: TextStyle(color: colorScheme.outline, fontSize: 13),
                        ),
                ),
                DataCell(
                  reading != null && reading.photoUrl != null && reading.photoUrl!.isNotEmpty
                      ? InkWell(
                          onTap: () => _showPhotoDialog(
                            context,
                            '${item.block.name} - Apto ${item.apartment.name} (${meterType.label})',
                            reading.photoUrl!,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          child: Tooltip(
                            message: 'Ver foto do medidor',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    reading.photoUrl!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.open_in_new, size: 14),
                              ],
                            ),
                          ),
                        )
                      : (reading != null && reading.photoPath != null && reading.photoPath!.isNotEmpty)
                          ? Tooltip(
                              message: 'Foto no dispositivo (${reading.photoPath})',
                              child: const Icon(Icons.photo_camera_outlined, size: 20, color: Colors.blueGrey),
                            )
                          : Text('—', style: TextStyle(color: colorScheme.outline)),
                ),
                DataCell(
                  Text(reading != null ? dateFormat.format(reading.readAt) : '—'),
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

  void _exportCsv(
    CondominiumReadingsOverview overview,
    MeterType meterType,
    DateTime month,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final buffer = StringBuffer();

    // Cabeçalho CSV com Competência e Detalhes de Consumo
    buffer.writeln(
      'Condominio;Administradora;Competencia;Tipo_Medicao;Bloco;Apartamento;Status;Leitura_Anterior_m3;Leitura_Atual_m3;Consumo_m3;Data_Leitura',
    );

    for (final item in overview.apartments) {
      final reading = item.latestReadingFor(meterType);
      final prev = item.previousReadingFor(meterType);
      final consumption = item.consumptionFor(meterType);
      final prevVal = prev != null ? prev.readingValue : '';
      final currVal = reading != null ? reading.readingValue : '';
      final consVal = consumption != null ? consumption.toStringAsFixed(3) : '';
      final dt = reading != null ? dateFormat.format(reading.readAt) : '';
      final status = item.hasReadingFor(meterType) ? 'LIDO' : 'PENDENTE';

      buffer.writeln(
        '"${overview.condominiumName}";"${overview.administratorName}";"$monthStr";"${meterType.label.toUpperCase()}";"${item.block.name}";"${item.apartment.name}";"$status";"$prevVal";"$currVal";"$consVal";"$dt"',
      );
    }

    if (kIsWeb) {
      final bytes = utf8.encode('\uFEFF${buffer.toString()}'); // BOM UTF-8 para Excel
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'relatorio_leituras_${meterType.name}_${month.year}_${month.month.toString().padLeft(2, '0')}_${overview.condominiumName.toLowerCase().replaceAll(' ', '_')}.csv',
        )
        ..click();
      html.Url.revokeObjectUrl(url);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Planilha CSV de ${meterType.label} ($monthStr) gerada e download iniciado com sucesso!'),
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, String title, String photoUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
          child: Image.network(
            photoUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Text('Não foi possível carregar a imagem do medidor.'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportPackagesSection(
    BuildContext context,
    CondominiumReadingsOverview overview,
    MeterType meterType,
    DateTime month,
  ) {
    final theme = Theme.of(context);
    final totalUnits = overview.totalApartments;
    final measuredUnits = overview.readingsCountFor(meterType);
    final withPhotoCount = overview.apartments.where((a) {
      final r = a.latestReadingFor(meterType);
      return r != null &&
          ((r.photoUrl != null && r.photoUrl!.isNotEmpty) ||
              (r.photoPath != null && r.photoPath!.isNotEmpty));
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Pacotes de Exportação e Fechamento (${meterType.label} - ${_formatMonthYear(month)})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Documentos e arquivos consolidados para envio à administradora do condomínio para rateio e auditoria.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth > 850
                ? (constraints.maxWidth - 32) / 3
                : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.red.shade50,
                                child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Espelho de Medição em PDF',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Gera o documento com dados de cada apartamento e a foto sequencial do medidor correspondente.',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                            onPressed: () => _openPdfMirrorDialog(context, overview, meterType, month),
                            icon: const Icon(Icons.visibility),
                            label: const Text('Visualizar / Imprimir PDF'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green.shade50,
                                child: const Icon(Icons.table_chart, color: Colors.green),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Planilha de Rateio (CSV/Excel)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Exportação com competência, dados anteriores, atuais e cálculo de consumo ($measuredUnits de $totalUnits unidades lidas).',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            onPressed: () => _exportCsv(overview, meterType, month),
                            icon: const Icon(Icons.download),
                            label: const Text('Baixar Planilha CSV'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.orange.shade50,
                                child: const Icon(Icons.folder_zip, color: Colors.orange),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Pacote ZIP de Fotos',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Arquivo compactado com todas as fotos capturadas ($withPhotoCount fotos anexadas de $totalUnits unidades).',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _downloadZipNotice(
                              context,
                              overview,
                              meterType,
                              month,
                              withPhotoCount,
                            ),
                            icon: const Icon(Icons.archive_outlined),
                            label: const Text('Pacote de Imagens'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _openPdfMirrorDialog(
    BuildContext context,
    CondominiumReadingsOverview overview,
    MeterType meterType,
    DateTime month,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 850),
          child: Scaffold(
            appBar: AppBar(
              title: Text('Espelho de Medição - ${overview.condominiumName} (${meterType.label})'),
              actions: [
                if (kIsWeb)
                  FilledButton.icon(
                    onPressed: () {
                      html.window.print();
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Imprimir / Salvar PDF'),
                  ),
                const SizedBox(width: 16),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              overview.condominiumName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text('Administradora: ${overview.administratorName}'),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Competência: ${_formatMonthYear(month)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('Tipo: ${meterType.label} (${meterType.unit})'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: overview.apartments.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, idx) {
                      final item = overview.apartments[idx];
                      final reading = item.latestReadingFor(meterType);
                      final prev = item.previousReadingFor(meterType);
                      final consumption = item.consumptionFor(meterType);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.block.name,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Apto ${item.apartment.name}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Leitura Anterior: ${prev != null ? '${prev.readingValue} ${meterType.unit}' : '—'}'),
                                    const SizedBox(width: 24),
                                    Text(
                                      'Leitura Atual: ${reading != null ? '${reading.readingValue} ${meterType.unit}' : 'Pendente'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: reading != null ? null : Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Text(
                                      'Consumo: ${consumption != null ? '+${consumption.toStringAsFixed(3)} ${meterType.unit}' : '—'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                  ],
                                ),
                                if (reading != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Registrado em: ${DateFormat('dd/MM/yyyy HH:mm').format(reading.readAt)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (reading != null && reading.photoUrl != null && reading.photoUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                reading.photoUrl!,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 90,
                                  height: 90,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image, size: 28),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_camera_outlined, size: 24, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text('Sem foto', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _downloadZipNotice(
    BuildContext context,
    CondominiumReadingsOverview overview,
    MeterType meterType,
    DateTime month,
    int photoCount,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pacote ZIP de Fotos'),
        content: Text(
          'Foram localizadas $photoCount fotografias de medidores de ${meterType.label} registradas no condomínio "${overview.condominiumName}" para a competência de ${_formatMonthYear(month)}.\n\n'
          'No app mobile do zelador, as imagens sincronizadas com o Firebase Storage são disponibilizadas em alta resolução para download direto ou envio integrado por e-mail/WhatsApp à administradora.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _openPdfMirrorDialog(context, overview, meterType, month);
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Ver no Espelho PDF'),
          ),
        ],
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
