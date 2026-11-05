import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';

class NewBlockPage extends ConsumerStatefulWidget {
  final String condominiumId;
  final String? administratorId;

  const NewBlockPage({
    super.key,
    required this.condominiumId,
    this.administratorId,
  });

  @override
  ConsumerState<NewBlockPage> createState() => _NewBlockPageState();
}

class _NewBlockPageState extends ConsumerState<NewBlockPage> {
  final _formKey = GlobalKey<FormState>();

  bool _bulkMode = false;
  bool _isActive = true;

  // Modo individual
  final _nameController = TextEditingController();

  // Modo em lote
  final _prefixController = TextEditingController(text: 'Bloco');
  final _countController = TextEditingController(text: '3');
  BlockNamingSequence _sequence = BlockNamingSequence.letters;

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
  void dispose() {
    _nameController.dispose();
    _prefixController.dispose();
    _countController.dispose();
    super.dispose();
  }

  List<String> get _previewBulkNames {
    final count = int.tryParse(_countController.text.trim()) ?? 0;
    if (count <= 0 || count > 50) return const [];
    return generateBulkBlockNames(
      prefix: _prefixController.text,
      count: count,
      sequence: _sequence,
    );
  }

  bool _canSubmitIndividual(CondominiumDetailsController controller) {
    final name = _nameController.text.trim();
    return name.isNotEmpty && !controller.hasBlockWithName(name);
  }

  bool _canSubmitBulk(CondominiumDetailsState state) {
    final count = int.tryParse(_countController.text.trim()) ?? 0;
    if (count <= 0 || count > 50) return false;
    final preview = _previewBulkNames;
    if (preview.isEmpty) return false;

    final existing = state.blocks
        .map((b) => b.block.name.trim().toLowerCase())
        .toSet();
    final newOnes = preview
        .where((name) => !existing.contains(name.trim().toLowerCase()))
        .toList();
    return newOnes.isNotEmpty;
  }

  Future<void> _submitIndividual({required bool goToApartments}) async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );
    final blockName = _nameController.text.trim();
    final createdId = await controller.createBlock(
      name: blockName,
      active: _isActive,
    );

    if (!mounted || createdId == null) return;

    final adminId = _effectiveAdminId(
      ref.read(condominiumDetailsControllerProvider(_scope)),
    );

    if (goToApartments) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bloco "$blockName" criado! Agora cadastre os apartamentos.',
          ),
        ),
      );
      context.go(
        AppRoutes.newApartmentPath(
          widget.condominiumId,
          administratorId: adminId,
          blockId: createdId,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bloco "$blockName" criado com sucesso.')),
      );
      context.go(
        AppRoutes.condominiumDetailsPath(
          widget.condominiumId,
          administratorId: adminId,
        ),
      );
    }
  }

  Future<void> _submitBulk() async {
    if (!_formKey.currentState!.validate()) return;

    final names = _previewBulkNames;
    if (names.isEmpty) return;

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );
    final result = await controller.createBlocksBatch(
      names: names,
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
          '${result.createdCount} ${result.createdCount == 1 ? 'bloco criado' : 'blocos criados'} com sucesso$skippedNote.',
        ),
      ),
    );

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 720;

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
              else ...[
                _buildModeSelector(state),
                const SizedBox(height: 20),
                _buildForm(context, state, controller, adminId, isSmall),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          label: const Text('Condomínio'),
        ),
        const SizedBox(height: 16),
        Text(
          'Novo bloco',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Cadastre um bloco individualmente ou gere vários blocos de uma vez.',
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

  Widget _buildModeSelector(CondominiumDetailsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.domain_outlined),
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

  Widget _buildForm(
    BuildContext context,
    CondominiumDetailsState state,
    CondominiumDetailsController controller,
    String? adminId,
    bool isSmall,
  ) {
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
                _buildBulkSection(context, state, isSmall)
              else
                _buildIndividualSection(context, state, controller),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(_bulkMode ? 'Blocos ativos' : 'Bloco ativo'),
                  subtitle: const Text(
                    'Disponível para vinculação de apartamentos e leituras.',
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
              _buildActions(context, state, controller, adminId, isSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndividualSection(
    BuildContext context,
    CondominiumDetailsState state,
    CondominiumDetailsController controller,
  ) {
    const baseSuggestions = [
      'Bloco Único',
      'Bloco A',
      'Bloco B',
      'Bloco C',
      'Torre 1',
      'Torre 2',
    ];
    final availableSuggestions = baseSuggestions
        .where((s) => !controller.hasBlockWithName(s))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cadastro individual de bloco',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text('Informe o nome ou identificação do bloco.'),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          enabled: !state.isSaving,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Nome do bloco *',
            hintText: 'Ex.: Bloco A ou Bloco Único',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.domain_outlined),
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Informe o nome do bloco.';
            }
            if (controller.hasBlockWithName(trimmed)) {
              return 'Já existe um bloco com este nome neste condomínio.';
            }
            return null;
          },
        ),
        if (availableSuggestions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Sugestões rápidas:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              ...availableSuggestions.map(
                (suggestion) => ActionChip(
                  label: Text(suggestion),
                  onPressed: state.isSaving
                      ? null
                      : () {
                          setState(() {
                            _nameController.text = suggestion;
                          });
                          _formKey.currentState?.validate();
                        },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBulkSection(
    BuildContext context,
    CondominiumDetailsState state,
    bool isSmall,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final preview = _previewBulkNames;
    final existingSet = state.blocks
        .map((b) => b.block.name.trim().toLowerCase())
        .toSet();
    final alreadyExistingCount = preview
        .where((name) => existingSet.contains(name.trim().toLowerCase()))
        .length;

    final prefixField = TextFormField(
      controller: _prefixController,
      enabled: !state.isSaving,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Prefixo',
        hintText: 'Ex.: Bloco ou Torre',
        prefixIcon: Icon(Icons.label_outline),
        border: OutlineInputBorder(),
      ),
    );

    final countField = TextFormField(
      controller: _countController,
      enabled: !state.isSaving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Quantidade de blocos *',
        hintText: 'Ex.: 4',
        prefixIcon: Icon(Icons.numbers),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        final count = int.tryParse(value?.trim() ?? '');
        if (count == null || count <= 0) {
          return 'Informe uma quantidade maior que zero.';
        }
        if (count > 50) {
          return 'Gere no máximo 50 blocos por vez.';
        }
        return null;
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gerar múltiplos blocos automaticamente',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Defina o prefixo, o tipo de sequência e a quantidade de blocos.',
        ),
        const SizedBox(height: 20),
        if (isSmall) ...[
          prefixField,
          const SizedBox(height: 16),
          countField,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: prefixField),
              const SizedBox(width: 16),
              Expanded(child: countField),
            ],
          ),
        const SizedBox(height: 16),
        Text(
          'Padrão da sequência',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SegmentedButton<BlockNamingSequence>(
          segments: const [
            ButtonSegment<BlockNamingSequence>(
              value: BlockNamingSequence.letters,
              label: Text('Letras (A, B, C...)'),
            ),
            ButtonSegment<BlockNamingSequence>(
              value: BlockNamingSequence.numbers,
              label: Text('Números (1, 2, 3...)'),
            ),
          ],
          selected: {_sequence},
          onSelectionChanged: state.isSaving
              ? null
              : (selection) {
                  setState(() {
                    _sequence = selection.first;
                  });
                },
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
                  'Prévia (${preview.length} ${preview.length == 1 ? 'bloco' : 'blocos'}):',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: preview.map((name) {
                    final exists = existingSet.contains(
                      name.trim().toLowerCase(),
                    );
                    return Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(exists ? '$name (já existe)' : name),
                      backgroundColor: exists
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.secondaryContainer,
                    );
                  }).toList(),
                ),
                if (alreadyExistingCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$alreadyExistingCount ${alreadyExistingCount == 1 ? 'bloco já existe e será ignorado' : 'blocos já existem e serão ignorados'}.',
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

  Widget _buildActions(
    BuildContext context,
    CondominiumDetailsState state,
    CondominiumDetailsController controller,
    String? adminId,
    bool isSmall,
  ) {
    final cancelBtn = OutlinedButton(
      onPressed: state.isSaving
          ? null
          : () => context.go(
              AppRoutes.condominiumDetailsPath(
                widget.condominiumId,
                administratorId: adminId,
              ),
            ),
      child: const Text('Cancelar'),
    );

    if (_bulkMode) {
      final canBulk = !state.isSaving && _canSubmitBulk(state);
      final generateBtn = FilledButton.icon(
        onPressed: canBulk ? _submitBulk : null,
        icon: state.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
        label: Text(state.isSaving ? 'Gerando...' : 'Gerar blocos'),
      );

      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 12,
        children: [cancelBtn, generateBtn],
      );
    }

    final canIndividual = !state.isSaving && _canSubmitIndividual(controller);

    final createOnlyBtn = FilledButton.tonal(
      onPressed: canIndividual
          ? () => _submitIndividual(goToApartments: false)
          : null,
      child: const Text('Criar bloco'),
    );

    final createAndApartmentsBtn = FilledButton.icon(
      onPressed: canIndividual
          ? () => _submitIndividual(goToApartments: true)
          : null,
      icon: state.isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_forward),
      label: Text(
        state.isSaving ? 'Salvando...' : 'Criar e cadastrar apartamentos',
      ),
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          createAndApartmentsBtn,
          const SizedBox(height: 10),
          createOnlyBtn,
          const SizedBox(height: 10),
          cancelBtn,
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 12,
      children: [cancelBtn, createOnlyBtn, createAndApartmentsBtn],
    );
  }
}
