import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/condominos/new_condominium_controller.dart';

const List<String> brazilianStates = [
  'AC',
  'AL',
  'AP',
  'AM',
  'BA',
  'CE',
  'DF',
  'ES',
  'GO',
  'MA',
  'MT',
  'MS',
  'MG',
  'PA',
  'PB',
  'PR',
  'PE',
  'PI',
  'RJ',
  'RN',
  'RS',
  'RO',
  'RR',
  'SC',
  'SP',
  'SE',
  'TO',
];

String formatCondominiumAddress({
  required String street,
  required String number,
  String? complement,
  required String neighborhood,
  required String city,
  required String uf,
  String? cep,
}) {
  final cleanStreet = street.trim();
  final cleanNumber = number.trim();
  final cleanComplement = complement?.trim() ?? '';
  final cleanNeighborhood = neighborhood.trim();
  final cleanCity = city.trim();
  final cleanUf = uf.trim().toUpperCase();
  final cepDigits = (cep ?? '').replaceAll(RegExp(r'\D'), '');

  final streetPart = [
    if (cleanStreet.isNotEmpty) cleanStreet,
    if (cleanNumber.isNotEmpty) cleanNumber,
  ].join(', ');

  final withComplement = cleanComplement.isNotEmpty && streetPart.isNotEmpty
      ? '$streetPart ($cleanComplement)'
      : (streetPart.isNotEmpty ? streetPart : cleanComplement);

  final cityUfPart = [
    if (cleanCity.isNotEmpty) cleanCity,
    if (cleanUf.isNotEmpty) cleanUf,
  ].join('/');

  final locationPart = [
    if (cleanNeighborhood.isNotEmpty) cleanNeighborhood,
    if (cityUfPart.isNotEmpty) cityUfPart,
  ].join(', ');

  final formattedCep = cepDigits.length == 8
      ? 'CEP ${cepDigits.substring(0, 5)}-${cepDigits.substring(5)}'
      : '';

  return [
    if (withComplement.isNotEmpty) withComplement,
    if (locationPart.isNotEmpty) locationPart,
    if (formattedCep.isNotEmpty) formattedCep,
  ].join(' - ');
}

class NewCondominiumPage extends ConsumerStatefulWidget {
  final String administratorId;

  const NewCondominiumPage({super.key, required this.administratorId});

  @override
  ConsumerState<NewCondominiumPage> createState() => _NewCondominiumPageState();
}

class _NewCondominiumPageState extends ConsumerState<NewCondominiumPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();

  final _streetFocusNode = FocusNode();
  final _numberFocusNode = FocusNode();

  String? _selectedUf;
  bool _hasNoNumber = false;
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _streetFocusNode.dispose();
    _numberFocusNode.dispose();
    super.dispose();
  }

  String get _cepDigits =>
      _cepController.text.replaceAll(RegExp(r'\D'), '');

  List<String> get _missingOrInvalidFields {
    final missing = <String>[];

    if (_nameController.text.trim().length < 3) {
      missing.add('Nome do condomínio');
    }

    if (_cepDigits.isNotEmpty && _cepDigits.length != 8) {
      missing.add('CEP completo (8 dígitos)');
    }

    if (_streetController.text.trim().length < 3) {
      missing.add('Logradouro');
    }

    if (!_hasNoNumber && _numberController.text.trim().isEmpty) {
      missing.add('Número');
    }

    if (_neighborhoodController.text.trim().length < 2) {
      missing.add('Bairro');
    }

    if (_cityController.text.trim().length < 2) {
      missing.add('Cidade');
    }

    if (_selectedUf == null || !brazilianStates.contains(_selectedUf)) {
      missing.add('UF');
    }

    return missing;
  }

  bool get _isFormReady => _missingOrInvalidFields.isEmpty;

  String get _formattedAddress => formatCondominiumAddress(
    street: _streetController.text,
    number: _hasNoNumber ? 'S/N' : _numberController.text,
    complement: _complementController.text,
    neighborhood: _neighborhoodController.text,
    city: _cityController.text,
    uf: _selectedUf ?? '',
    cep: _cepController.text,
  );

  void _onFieldChanged() {
    setState(() {});
  }

  void _onCepChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    setState(() {});

    final controller = ref.read(
      newCondominiumControllerProvider(widget.administratorId).notifier,
    );

    if (digits.isEmpty) {
      controller.clearCepFeedback();
      return;
    }

    if (digits.length == 8) {
      _handleCepLookup(digits);
    }
  }

  void _clearCep() {
    _cepController.clear();
    ref
        .read(newCondominiumControllerProvider(widget.administratorId).notifier)
        .clearCepFeedback();
    setState(() {});
  }

  Future<void> _handleCepLookup(String digits, {bool force = false}) async {
    final controller = ref.read(
      newCondominiumControllerProvider(widget.administratorId).notifier,
    );

    final result = await controller.lookupCep(digits, force: force);
    if (!mounted || result == null) return;

    setState(() {
      if (result.street.isNotEmpty) {
        _streetController.text = result.street;
      }
      if (result.neighborhood.isNotEmpty) {
        _neighborhoodController.text = result.neighborhood;
      }
      if (result.city.isNotEmpty) {
        _cityController.text = result.city;
      }
      if (brazilianStates.contains(result.uf)) {
        _selectedUf = result.uf;
      }
      if (result.complement.isNotEmpty &&
          _complementController.text.trim().isEmpty) {
        _complementController.text = result.complement;
      }
    });

    _formKey.currentState?.validate();

    if (result.street.isEmpty) {
      _streetFocusNode.requestFocus();
    } else if (!_hasNoNumber && _numberController.text.trim().isEmpty) {
      _numberFocusNode.requestFocus();
    }
  }

  void _toggleNoNumber(bool selected) {
    setState(() {
      _hasNoNumber = selected;
      if (selected) {
        _numberController.text = 'S/N';
      } else {
        if (_numberController.text.trim() == 'S/N') {
          _numberController.clear();
        }
        _numberFocusNode.requestFocus();
      }
    });
    _formKey.currentState?.validate();
  }

  Future<void> _submit({required bool proceedToBlocks}) async {
    if (!_formKey.currentState!.validate() || !_isFormReady) {
      return;
    }

    final controller = ref.read(
      newCondominiumControllerProvider(widget.administratorId).notifier,
    );

    final createdId = await controller.createCondominium(
      name: _nameController.text.trim(),
      address: _formattedAddress,
      active: _isActive,
    );

    if (!mounted || createdId == null) {
      return;
    }

    if (proceedToBlocks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Condomínio cadastrado com sucesso! Próxima etapa: blocos.',
          ),
        ),
      );
      context.go(
        AppRoutes.condominiumBlocksPath(
          createdId,
          administratorId: widget.administratorId,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Condomínio cadastrado com sucesso!'),
        ),
      );
      context.go(AppRoutes.administratorDetailsPath(widget.administratorId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      newCondominiumControllerProvider(widget.administratorId),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 760;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state),
              const SizedBox(height: 28),
              if (state.isLoadingAdmin)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (state.adminError != null)
                _buildAdminError(context, state.adminError!)
              else ...[
                _buildSteps(context, isSmall),
                const SizedBox(height: 28),
                _buildForm(context, state, isSmall),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, NewCondominiumState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final administrator = state.administrator;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: state.isSaving
              ? null
              : () => context.go(
                  AppRoutes.administratorDetailsPath(widget.administratorId),
                ),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Administradora'),
        ),
        const SizedBox(height: 16),
        Text(
          'Novo condomínio',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Cadastre o condomínio e configure sua estrutura operacional.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (administrator != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                avatar: Icon(
                  Icons.business_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                label: Text('Administradora: ${administrator.name}'),
              ),
              if (!administrator.active)
                Chip(
                  avatar: Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  backgroundColor: colorScheme.tertiaryContainer,
                  label: Text(
                    'Administradora inativa',
                    style: TextStyle(color: colorScheme.onTertiaryContainer),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAdminError(BuildContext context, String errorMessage) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Não foi possível carregar a administradora',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.administrators),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar para administradoras'),
                  ),
                  FilledButton.icon(
                    onPressed: () => ref
                        .read(
                          newCondominiumControllerProvider(
                            widget.administratorId,
                          ).notifier,
                        )
                        .loadAdministrator(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSteps(BuildContext context, bool isSmall) {
    const steps = [
      'Informações',
      'Blocos',
      'Apartamentos',
      'Contas',
      'Conclusão',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isSmall
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Etapa 1 de 5',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Informações',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: 1 / steps.length),
                ],
              )
            : Row(
                children: List.generate(steps.length, (index) {
                  final isCurrent = index == 0;

                  return Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            steps[index],
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (index < steps.length - 1)
                          const Expanded(
                            child: Divider(indent: 8, endIndent: 8),
                          ),
                      ],
                    ),
                  );
                }),
              ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    NewCondominiumState state,
    bool isSmall,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final canSubmit = _isFormReady && !state.isSaving;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 20 : 28),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identificação do condomínio',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Campos marcados com * são obrigatórios.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                enabled: !state.isSaving,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _onFieldChanged(),
                decoration: const InputDecoration(
                  labelText: 'Nome do condomínio *',
                  hintText: 'Ex.: Residencial Jardim das Acácias',
                  prefixIcon: Icon(Icons.apartment_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Informe o nome do condomínio.';
                  }
                  if (trimmed.length < 3) {
                    return 'O nome deve ter pelo menos 3 caracteres.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Condomínio ativo'),
                  subtitle: const Text(
                    'Disponível para configuração e operação de leituras.',
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

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Endereço do condomínio',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Você pode informar o CEP para preenchimento automático ou digitar o endereço manualmente.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildCepSection(context, state, isSmall),

              const SizedBox(height: 20),

              _buildStreetAndNumberRow(state, isSmall),

              const SizedBox(height: 16),

              _buildComplementAndNeighborhoodRow(state, isSmall),

              const SizedBox(height: 16),

              _buildCityAndUfRow(state, isSmall),

              const SizedBox(height: 24),

              _buildAddressPreviewAndStatus(context, state),

              if (state.saveError != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.saveError!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              _buildActions(context, state, canSubmit, isSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCepSection(
    BuildContext context,
    NewCondominiumState state,
    bool isSmall,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final canSearchCep =
        _cepDigits.length == 8 && !state.isLookingUpCep && !state.isSaving;

    final cepField = TextFormField(
      controller: _cepController,
      enabled: !state.isSaving,
      keyboardType: TextInputType.number,
      inputFormatters: [_CepInputFormatter()],
      onChanged: _onCepChanged,
      decoration: InputDecoration(
        labelText: 'CEP (opcional)',
        hintText: '00000-000',
        helperText: state.cepMessage == null
            ? 'Opcional: preenche rua, bairro, cidade e UF automaticamente.'
            : null,
        prefixIcon: const Icon(Icons.pin_drop_outlined),
        border: const OutlineInputBorder(),
        suffixIcon: state.isLookingUpCep
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_cepController.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Limpar CEP',
                      onPressed: state.isSaving ? null : _clearCep,
                      icon: const Icon(Icons.clear),
                    ),
                  IconButton(
                    tooltip: 'Buscar endereço pelo CEP',
                    onPressed: canSearchCep
                        ? () => _handleCepLookup(_cepDigits, force: true)
                        : null,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
      ),
      validator: (value) {
        final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
        if (digits.isNotEmpty && digits.length != 8) {
          return 'Complete os 8 dígitos do CEP ou deixe o campo em branco.';
        }
        return null;
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isSmall)
          cepField
        else
          SizedBox(width: 360, child: cepField),
        if (state.cepMessage != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: state.isCepSuccess
                  ? colorScheme.secondaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.isCepSuccess
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 18,
                  color: state.isCepSuccess
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    state.cepMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: state.isCepSuccess
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStreetAndNumberRow(NewCondominiumState state, bool isSmall) {
    final streetField = TextFormField(
      controller: _streetController,
      focusNode: _streetFocusNode,
      enabled: !state.isSaving,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => _onFieldChanged(),
      decoration: const InputDecoration(
        labelText: 'Logradouro (Rua / Avenida) *',
        hintText: 'Ex.: Rua das Flores',
        prefixIcon: Icon(Icons.signpost_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Informe o logradouro.';
        }
        if (trimmed.length < 3) {
          return 'Informe um logradouro válido.';
        }
        return null;
      },
    );

    final numberField = TextFormField(
      controller: _numberController,
      focusNode: _numberFocusNode,
      enabled: !state.isSaving && !_hasNoNumber,
      onChanged: (_) => _onFieldChanged(),
      decoration: const InputDecoration(
        labelText: 'Número *',
        hintText: 'Ex.: 100',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (_hasNoNumber) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Informe o número.';
        }
        return null;
      },
    );

    final noNumberChip = FilterChip(
      label: const Text('Sem número (S/N)'),
      selected: _hasNoNumber,
      onSelected: state.isSaving ? null : _toggleNoNumber,
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          streetField,
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: numberField),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: noNumberChip,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: streetField),
        const SizedBox(width: 16),
        SizedBox(width: 160, child: numberField),
        const SizedBox(width: 12),
        Padding(padding: const EdgeInsets.only(top: 6), child: noNumberChip),
      ],
    );
  }

  Widget _buildComplementAndNeighborhoodRow(
    NewCondominiumState state,
    bool isSmall,
  ) {
    final complementField = TextFormField(
      controller: _complementController,
      enabled: !state.isSaving,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) => _onFieldChanged(),
      decoration: const InputDecoration(
        labelText: 'Complemento (opcional)',
        hintText: 'Ex.: Portaria Principal, Quadra 2',
        border: OutlineInputBorder(),
      ),
    );

    final neighborhoodField = TextFormField(
      controller: _neighborhoodController,
      enabled: !state.isSaving,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => _onFieldChanged(),
      decoration: const InputDecoration(
        labelText: 'Bairro *',
        hintText: 'Ex.: Centro',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Informe o bairro.';
        }
        if (trimmed.length < 2) {
          return 'Informe um bairro válido.';
        }
        return null;
      },
    );

    if (isSmall) {
      return Column(
        children: [
          neighborhoodField,
          const SizedBox(height: 16),
          complementField,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: neighborhoodField),
        const SizedBox(width: 16),
        Expanded(child: complementField),
      ],
    );
  }

  Widget _buildCityAndUfRow(NewCondominiumState state, bool isSmall) {
    final cityField = TextFormField(
      controller: _cityController,
      enabled: !state.isSaving,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => _onFieldChanged(),
      decoration: const InputDecoration(
        labelText: 'Cidade *',
        hintText: 'Ex.: São Paulo',
        prefixIcon: Icon(Icons.location_city_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Informe a cidade.';
        }
        if (trimmed.length < 2) {
          return 'Informe uma cidade válida.';
        }
        return null;
      },
    );

    final ufDropdown = DropdownButtonFormField<String>(
      key: ValueKey(_selectedUf),
      initialValue: _selectedUf,
      decoration: const InputDecoration(
        labelText: 'UF *',
        border: OutlineInputBorder(),
      ),
      items: brazilianStates
          .map((uf) => DropdownMenuItem<String>(value: uf, child: Text(uf)))
          .toList(),
      onChanged: state.isSaving
          ? null
          : (value) {
              setState(() {
                _selectedUf = value;
              });
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione a UF.';
        }
        return null;
      },
    );

    if (isSmall) {
      return Column(
        children: [
          cityField,
          const SizedBox(height: 16),
          ufDropdown,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: cityField),
        const SizedBox(width: 16),
        SizedBox(width: 160, child: ufDropdown),
      ],
    );
  }

  Widget _buildAddressPreviewAndStatus(
    BuildContext context,
    NewCondominiumState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final preview = _formattedAddress;
    final missing = _missingOrInvalidFields;

    return Container(
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
          Row(
            children: [
              Icon(
                missing.isEmpty
                    ? Icons.verified_outlined
                    : Icons.assignment_outlined,
                size: 20,
                color: missing.isEmpty
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  missing.isEmpty
                      ? 'Dados obrigatórios preenchidos'
                      : 'Itens pendentes para liberar o cadastro: ${missing.join(', ')}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: missing.isEmpty
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Endereço formatado: $preview',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    NewCondominiumState state,
    bool canSubmit,
    bool isSmall,
  ) {
    final cancelBtn = OutlinedButton(
      onPressed: state.isSaving
          ? null
          : () => context.go(
              AppRoutes.administratorDetailsPath(widget.administratorId),
            ),
      child: const Text('Cancelar'),
    );

    final saveAndReturnBtn = FilledButton.tonal(
      onPressed: canSubmit ? () => _submit(proceedToBlocks: false) : null,
      child: const Text('Salvar e voltar'),
    );

    final saveAndContinueBtn = FilledButton.icon(
      onPressed: canSubmit ? () => _submit(proceedToBlocks: true) : null,
      icon: state.isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_forward),
      label: Text(
        state.isSaving ? 'Salvando...' : 'Salvar e configurar blocos',
      ),
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          saveAndContinueBtn,
          const SizedBox(height: 10),
          saveAndReturnBtn,
          const SizedBox(height: 10),
          cancelBtn,
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 12,
      children: [cancelBtn, saveAndReturnBtn, saveAndContinueBtn],
    );
  }
}

class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated = digitsOnly.length > 8
        ? digitsOnly.substring(0, 8)
        : digitsOnly;

    final String formatted;
    if (truncated.length > 5) {
      formatted = '${truncated.substring(0, 5)}-${truncated.substring(5)}';
    } else {
      formatted = truncated;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
