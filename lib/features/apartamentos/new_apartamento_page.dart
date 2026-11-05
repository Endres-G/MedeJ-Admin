import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';

class NewApartmentPage extends ConsumerStatefulWidget {
  final String condominiumId;
  final String? administratorId;
  final String? blockId;

  const NewApartmentPage({
    super.key,
    required this.condominiumId,
    this.administratorId,
    this.blockId,
  });

  @override
  ConsumerState<NewApartmentPage> createState() => _NewApartmentPageState();
}

class _NewApartmentPageState extends ConsumerState<NewApartmentPage> {
  static const int _maxPreviewChips = 36;

  final _formKey = GlobalKey<FormState>();

  bool _bulkMode = false;
  bool _isActive = true;
  String? _selectedBlockId;

  // Modo individual
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  // Modo em lote
  final _floorsController = TextEditingController(text: '4');
  final _apartmentsPerFloorController = TextEditingController(text: '4');
  final _firstNumberController = TextEditingController(text: '101');
  ApartmentNumberingPattern _pattern = ApartmentNumberingPattern.hundreds;

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

  String? _effectiveBlockId(CondominiumDetailsState state) {
    if (state.blocks.isEmpty) return null;

    final validIds = state.blocks.map((b) => b.block.id).toSet();

    if (_selectedBlockId != null && validIds.contains(_selectedBlockId)) {
      return _selectedBlockId;
    }

    if (widget.blockId != null && validIds.contains(widget.blockId)) {
      return widget.blockId;
    }

    final firstActive = state.blocks.where((b) => b.block.active).toList();
    if (firstActive.isNotEmpty) {
      return firstActive.first.block.id;
    }

    return state.blocks.first.block.id;
  }

  @override
  void initState() {
    super.initState();
    if (widget.blockId != null && widget.blockId!.trim().isNotEmpty) {
      _selectedBlockId = widget.blockId!.trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _floorsController.dispose();
    _apartmentsPerFloorController.dispose();
    _firstNumberController.dispose();
    super.dispose();
  }

  int get _maxUnitsPerFloorForPattern {
    switch (_pattern) {
      case ApartmentNumberingPattern.hundreds:
        return 99;
      case ApartmentNumberingPattern.tens:
        return 9;
      case ApartmentNumberingPattern.sequential:
        return 50;
    }
  }

  List<String> get _previewBulkNumbers {
    final floors = int.tryParse(_floorsController.text.trim()) ?? 0;
    final perFloor =
        int.tryParse(_apartmentsPerFloorController.text.trim()) ?? 0;
    final first = int.tryParse(_firstNumberController.text.trim());

    if (floors <= 0 ||
        floors > 80 ||
        perFloor <= 0 ||
        perFloor > _maxUnitsPerFloorForPattern ||
        first == null ||
        first < 1) {
      return const [];
    }

    return generateBulkApartmentNumbers(
      floors: floors,
      apartmentsPerFloor: perFloor,
      firstNumber: first,
      pattern: _pattern,
    );
  }

  bool _canSubmitIndividual(
    CondominiumDetailsState state,
    CondominiumDetailsController controller,
    String? blockId,
  ) {
    if (blockId == null || blockId.isEmpty) return false;
    final name = _nameController.text.trim();
    if (name.isEmpty) return false;
    return !controller.hasApartmentInBlock(blockId, name);
  }

  bool _canSubmitBulk(CondominiumDetailsState state, String? blockId) {
    if (blockId == null || blockId.isEmpty) return false;
    final generated = _previewBulkNumbers;
    if (generated.isEmpty) return false;

    final blockItem = state.findBlock(blockId);
    if (blockItem == null) return false;

    final existing = blockItem.apartments
        .map((a) => a.name.trim().toLowerCase())
        .toSet();
    final newOnes = generated
        .where((n) => !existing.contains(n.trim().toLowerCase()))
        .toList();

    return newOnes.isNotEmpty;
  }

  void _onPatternChanged(ApartmentNumberingPattern nextPattern) {
    final currentFirst = _firstNumberController.text.trim();
    setState(() {
      _pattern = nextPattern;
      if (nextPattern == ApartmentNumberingPattern.hundreds &&
          (currentFirst == '11' || currentFirst == '1')) {
        _firstNumberController.text = '101';
      } else if (nextPattern == ApartmentNumberingPattern.tens &&
          (currentFirst == '101' || currentFirst == '1')) {
        _firstNumberController.text = '11';
      } else if (nextPattern == ApartmentNumberingPattern.sequential &&
          (currentFirst == '101' || currentFirst == '11')) {
        _firstNumberController.text = '1';
      }
    });
    _formKey.currentState?.validate();
  }

  Future<void> _submitIndividual({
    required String blockId,
    required bool keepAdding,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );
    final apartmentName = _nameController.text.trim();

    final createdId = await controller.createApartment(
      blockId: blockId,
      name: apartmentName,
      active: _isActive,
    );

    if (!mounted || createdId == null) return;

    if (keepAdding) {
      setState(() {
        _selectedBlockId = blockId;
        _nameController.clear();
      });
      _nameFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Apartamento $apartmentName salvo! Digite o próximo número.',
          ),
        ),
      );
      return;
    }

    final adminId = _effectiveAdminId(
      ref.read(condominiumDetailsControllerProvider(_scope)),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Apartamento $apartmentName criado com sucesso.'),
      ),
    );
    _navigateBackAfterFinish(adminId);
  }

  Future<void> _submitBulk({required String blockId}) async {
    if (!_formKey.currentState!.validate()) return;

    final generated = _previewBulkNumbers;
    if (generated.isEmpty) return;

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );
    final result = await controller.createApartmentsBatch(
      blockId: blockId,
      names: generated,
      active: _isActive,
    );

    if (!mounted || result == null) return;

    final adminId = _effectiveAdminId(
      ref.read(condominiumDetailsControllerProvider(_scope)),
    );

    final skippedNote = result.skippedCount > 0
        ? ' (${result.skippedCount} já existentes ignorados)'
        : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.createdCount} ${result.createdCount == 1 ? 'apartamento gerado' : 'apartamentos gerados'} com sucesso$skippedNote.',
        ),
      ),
    );

    _navigateBackAfterFinish(adminId);
  }

  void _navigateBackAfterFinish(String? adminId) {
    context.go(
      AppRoutes.condominiumDetailsPath(
        widget.condominiumId,
        administratorId: adminId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(condominiumDetailsControllerProvider(_scope));
    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );
    final adminId = _effectiveAdminId(state);
    final effectiveBlockId = _effectiveBlockId(state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 740;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state, adminId),
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
              else if (state.blocks.isEmpty)
                _buildNoBlocksCard(context, adminId)
              else ...[
                _buildModeSelector(state),
                const SizedBox(height: 20),
                _buildForm(
                  context: context,
                  state: state,
                  controller: controller,
                  effectiveBlockId: effectiveBlockId,
                  adminId: adminId,
                  isSmall: isSmall,
                ),
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
    String? adminId,
  ) {
    final condoName = state.condominium?.name.trim() ?? '';
    final originBlock =
        widget.blockId != null && widget.blockId!.trim().isNotEmpty
        ? state.findBlock(widget.blockId!)?.block
        : null;

    final backToCondoLabel = condoName.isNotEmpty
        ? 'Voltar para $condoName'
        : 'Voltar para Condomínio';
    final apartmentsListLabel = condoName.isNotEmpty
        ? 'Apartamentos de $condoName'
        : 'Lista de apartamentos';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: state.isSaving
                  ? null
                  : () => context.go(
                      AppRoutes.condominiumDetailsPath(
                        widget.condominiumId,
                        administratorId: adminId,
                      ),
                    ),
              icon: const Icon(Icons.arrow_back),
              label: Text(backToCondoLabel),
            ),
            if (originBlock != null)
              TextButton.icon(
                onPressed: state.isSaving
                    ? null
                    : () => context.go(
                        AppRoutes.blockDetailsPath(
                          widget.condominiumId,
                          originBlock.id,
                          administratorId: adminId,
                        ),
                      ),
                icon: const Icon(Icons.domain_outlined),
                label: Text('Bloco: ${originBlock.name}'),
              ),
            TextButton.icon(
              onPressed: state.isSaving
                  ? null
                  : () => context.go(
                      AppRoutes.condominiumApartmentsPath(
                        widget.condominiumId,
                        administratorId: adminId,
                      ),
                    ),
              icon: const Icon(Icons.home_work_outlined),
              label: Text(apartmentsListLabel),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Novo apartamento',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Cadastre um apartamento individualmente ou gere vários andares de uma só vez.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (state.condominium != null) ...[
          const SizedBox(height: 10),
          Chip(
            avatar: Icon(
              Icons.apartment_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text('Condomínio: ${state.condominium!.name}'),
          ),
        ],
      ],
    );
  }

  Widget _buildNoBlocksCard(BuildContext context, String? adminId) {
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
                'Nenhum bloco cadastrado neste condomínio',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Crie primeiro um bloco (ex.: Bloco A ou Bloco Único) para vincular os apartamentos a ele.',
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
                label: const Text('Criar bloco agora'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(CondominiumDetailsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.home_outlined),
              label: Text('Individual'),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.auto_awesome_outlined),
              label: Text('Gerar em lote'),
            ),
          ],
          selected: {_bulkMode},
          onSelectionChanged: state.isSaving
              ? null
              : (selection) {
                  setState(() {
                    _bulkMode = selection.first;
                  });
                },
        ),
      ),
    );
  }

  Widget _buildForm({
    required BuildContext context,
    required CondominiumDetailsState state,
    required CondominiumDetailsController controller,
    required String? effectiveBlockId,
    required String? adminId,
    required bool isSmall,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 20 : 28),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_bulkMode)
                _buildBulkSection(context, state, effectiveBlockId, isSmall)
              else
                _buildIndividualSection(
                  context,
                  state,
                  controller,
                  effectiveBlockId,
                ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(
                    _bulkMode ? 'Apartamentos ativos' : 'Apartamento ativo',
                  ),
                  subtitle: const Text(
                    'Disponível para registro de leituras e vínculo de contas.',
                  ),
                  value: _isActive,
                  onChanged: state.isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                ),
              ),

              if (state.actionError != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.actionError!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              _buildActions(
                context: context,
                state: state,
                controller: controller,
                effectiveBlockId: effectiveBlockId,
                adminId: adminId,
                isSmall: isSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockDropdown(
    CondominiumDetailsState state,
    String? effectiveBlockId,
  ) {
    return DropdownButtonFormField<String>(
      key: ValueKey(effectiveBlockId),
      initialValue: effectiveBlockId,
      decoration: const InputDecoration(
        labelText: 'Bloco *',
        prefixIcon: Icon(Icons.domain_outlined),
        border: OutlineInputBorder(),
      ),
      items: state.blocks.map((item) {
        final suffix = item.block.active ? '' : ' (Inativo)';
        return DropdownMenuItem<String>(
          value: item.block.id,
          child: Text(
            '${item.block.name}$suffix (${item.totalApartments} aptos)',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: state.isSaving
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                _selectedBlockId = value;
              });
              _formKey.currentState?.validate();
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione um bloco.';
        }
        return null;
      },
    );
  }

  Widget _buildIndividualSection(
    BuildContext context,
    CondominiumDetailsState state,
    CondominiumDetailsController controller,
    String? effectiveBlockId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cadastro individual',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text('Selecione o bloco e informe a identificação da unidade.'),
        const SizedBox(height: 20),
        _buildBlockDropdown(state, effectiveBlockId),
        const SizedBox(height: 18),
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          enabled: !state.isSaving,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Número / Identificação do apartamento *',
            hintText: 'Ex.: 101, 102B, Térreo 01, Cobertura 01',
            prefixIcon: Icon(Icons.home_work_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Informe o número ou identificação do apartamento.';
            }
            if (effectiveBlockId != null &&
                controller.hasApartmentInBlock(effectiveBlockId, trimmed)) {
              return 'Este apartamento já está cadastrado no bloco selecionado.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBulkSection(
    BuildContext context,
    CondominiumDetailsState state,
    String? effectiveBlockId,
    bool isSmall,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final preview = _previewBulkNumbers;
    final selectedBlockItem = effectiveBlockId != null
        ? state.findBlock(effectiveBlockId)
        : null;
    final existingSet =
        selectedBlockItem?.apartments
            .map((a) => a.name.trim().toLowerCase())
            .toSet() ??
        const <String>{};
    final duplicateCount = preview
        .where((n) => existingSet.contains(n.trim().toLowerCase()))
        .length;

    final floorsField = TextFormField(
      controller: _floorsController,
      enabled: !state.isSaving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Quantidade de andares *',
        hintText: 'Ex.: 10',
        prefixIcon: Icon(Icons.layers_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        final number = int.tryParse(value?.trim() ?? '');
        if (number == null || number <= 0) {
          return 'Informe ao menos 1 andar.';
        }
        if (number > 80) {
          return 'Máximo de 80 andares por geração.';
        }
        return null;
      },
    );

    final perFloorField = TextFormField(
      controller: _apartmentsPerFloorController,
      enabled: !state.isSaving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: 'Apartamentos por andar *',
        hintText: 'Ex.: 4',
        prefixIcon: const Icon(Icons.grid_view_outlined),
        border: const OutlineInputBorder(),
        helperText: _pattern == ApartmentNumberingPattern.tens
            ? 'No padrão de dezena (11, 21...), máximo de 9 por andar.'
            : null,
      ),
      validator: (value) {
        final number = int.tryParse(value?.trim() ?? '');
        if (number == null || number <= 0) {
          return 'Informe ao menos 1 apartamento.';
        }
        if (number > _maxUnitsPerFloorForPattern) {
          return 'Máximo de $_maxUnitsPerFloorForPattern por andar neste padrão.';
        }
        return null;
      },
    );

    final firstNumberField = TextFormField(
      controller: _firstNumberController,
      enabled: !state.isSaving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Primeiro apartamento *',
        hintText: 'Ex.: 101',
        prefixIcon: Icon(Icons.looks_one_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        final number = int.tryParse(value?.trim() ?? '');
        if (number == null || number < 1) {
          return 'Informe um número inicial válido.';
        }
        return null;
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gerar apartamentos em lote',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Configure os andares e confira a prévia exata das unidades antes de confirmar.',
        ),
        const SizedBox(height: 20),
        _buildBlockDropdown(state, effectiveBlockId),
        const SizedBox(height: 18),
        Text(
          'Padrão de numeração',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SegmentedButton<ApartmentNumberingPattern>(
          segments: const [
            ButtonSegment<ApartmentNumberingPattern>(
              value: ApartmentNumberingPattern.hundreds,
              label: Text('Centena (101, 201...)'),
            ),
            ButtonSegment<ApartmentNumberingPattern>(
              value: ApartmentNumberingPattern.tens,
              label: Text('Dezena (11, 21...)'),
            ),
            ButtonSegment<ApartmentNumberingPattern>(
              value: ApartmentNumberingPattern.sequential,
              label: Text('Sequencial (1, 2...)'),
            ),
          ],
          selected: {_pattern},
          onSelectionChanged: state.isSaving
              ? null
              : (selection) => _onPatternChanged(selection.first),
        ),
        const SizedBox(height: 18),
        if (isSmall) ...[
          floorsField,
          const SizedBox(height: 16),
          perFloorField,
          const SizedBox(height: 16),
          firstNumberField,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: floorsField),
              const SizedBox(width: 16),
              Expanded(child: perFloorField),
              const SizedBox(width: 16),
              Expanded(child: firstNumberField),
            ],
          ),
        if (preview.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prévia: ${preview.length} ${preview.length == 1 ? 'apartamento será gerado' : 'apartamentos serão gerados'}${selectedBlockItem != null ? ' em ${selectedBlockItem.block.name}' : ''}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...preview.take(_maxPreviewChips).map((numStr) {
                      final exists = existingSet.contains(
                        numStr.trim().toLowerCase(),
                      );
                      return Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(exists ? '$numStr (já existe)' : numStr),
                        backgroundColor: exists
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.secondaryContainer,
                      );
                    }),
                    if (preview.length > _maxPreviewChips)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '+ ${preview.length - _maxPreviewChips} apartamentos (até ${preview.last})',
                        ),
                      ),
                  ],
                ),
                if (duplicateCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$duplicateCount ${duplicateCount == 1 ? 'unidade já existe neste bloco e será ignorada' : 'unidades já existem neste bloco e serão ignoradas'}.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions({
    required BuildContext context,
    required CondominiumDetailsState state,
    required CondominiumDetailsController controller,
    required String? effectiveBlockId,
    required String? adminId,
    required bool isSmall,
  }) {
    final cancelBtn = OutlinedButton(
      onPressed: state.isSaving
          ? null
          : () => _navigateBackAfterFinish(adminId),
      child: const Text('Cancelar'),
    );

    if (_bulkMode) {
      final canBulk =
          !state.isSaving && _canSubmitBulk(state, effectiveBlockId);
      final generateBtn = FilledButton.icon(
        onPressed: canBulk && effectiveBlockId != null
            ? () => _submitBulk(blockId: effectiveBlockId)
            : null,
        icon: state.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
        label: Text(state.isSaving ? 'Gerando...' : 'Gerar apartamentos'),
      );

      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 12,
        children: [cancelBtn, generateBtn],
      );
    }

    final canIndividual =
        !state.isSaving &&
        _canSubmitIndividual(state, controller, effectiveBlockId);

    final saveAndAnotherBtn = FilledButton.tonal(
      onPressed: canIndividual && effectiveBlockId != null
          ? () => _submitIndividual(blockId: effectiveBlockId, keepAdding: true)
          : null,
      child: const Text('Salvar e adicionar outro'),
    );

    final createBtn = FilledButton.icon(
      onPressed: canIndividual && effectiveBlockId != null
          ? () => _submitIndividual(
              blockId: effectiveBlockId,
              keepAdding: false,
            )
          : null,
      icon: state.isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check),
      label: Text(state.isSaving ? 'Salvando...' : 'Criar apartamento'),
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          createBtn,
          const SizedBox(height: 10),
          saveAndAnotherBtn,
          const SizedBox(height: 10),
          cancelBtn,
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 12,
      children: [cancelBtn, saveAndAnotherBtn, createBtn],
    );
  }
}
