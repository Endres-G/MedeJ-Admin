import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/admin/admin_details_controller.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';

class AdminDetailsPage extends ConsumerStatefulWidget {
  final String administratorId;

  const AdminDetailsPage({super.key, required this.administratorId});

  @override
  ConsumerState<AdminDetailsPage> createState() => _AdminDetailsPageState();
}

class _AdminDetailsPageState extends ConsumerState<AdminDetailsPage> {
  String _search = '';

  List<CondominiumOverviewItem> _filterCondominiums(
    List<CondominiumOverviewItem> items,
  ) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) {
      return items;
    }

    return items.where((item) {
      return item.condominium.name.toLowerCase().contains(query) ||
          item.condominium.address.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      adminDetailsControllerProvider(widget.administratorId),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, state),
              const SizedBox(height: 24),
              if (state.isLoading && state.administrator == null)
                _buildLoadingState()
              else if (state.error != null && state.administrator == null)
                _buildErrorState(context, state.error!)
              else if (state.administrator != null) ...[
                _buildHeader(context, state.administrator!, state, isSmall),
                const SizedBox(height: 32),
                if (state.error != null)
                  _buildErrorState(context, state.error!)
                else if (state.isLoading)
                  _buildLoadingState()
                else ...[
                  _buildSummary(context, state),
                  const SizedBox(height: 32),
                  _buildCondominiums(context, state, isSmall),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, AdminDetailsState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () => context.go(AppRoutes.administrators),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Voltar para Administradoras'),
        ),
        IconButton(
          tooltip: 'Atualizar dados',
          onPressed: state.isLoading
              ? null
              : () => ref
                    .read(
                      adminDetailsControllerProvider(
                        widget.administratorId,
                      ).notifier,
                    )
                    .load(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 56, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando dados da administradora...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Não foi possível carregar os dados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref
                      .read(
                        adminDetailsControllerProvider(
                          widget.administratorId,
                        ).notifier,
                      )
                      .load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdministratorModel administrator,
    AdminDetailsState state,
    bool isSmall,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhone =
        administrator.phone != null && administrator.phone!.trim().isNotEmpty;

    final infoSection = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          child: Icon(
            Icons.business_outlined,
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
                administrator.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        administrator.email,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  if (hasPhone)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          administrator.phone!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  if (administrator.createdAt != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Desde ${_formatDate(administrator.createdAt!)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Chip(
                label: Text(administrator.active ? 'Ativa' : 'Inativa'),
                backgroundColor: administrator.active
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
        ),
      ],
    );

    final actionsSection = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: state.isSaving
              ? null
              : () => _showEditAdministratorDialog(administrator),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
        ),
        OutlinedButton.icon(
          onPressed: state.isSaving
              ? null
              : () => _confirmAndToggleActive(administrator),
          icon: Icon(
            administrator.active
                ? Icons.pause_circle_outline
                : Icons.check_circle_outline,
          ),
          label: Text(administrator.active ? 'Desativar' : 'Ativar'),
        ),
      ],
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [infoSection, const SizedBox(height: 16), actionsSection],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: infoSection),
        const SizedBox(width: 16),
        actionsSection,
      ],
    );
  }

  Widget _buildSummary(BuildContext context, AdminDetailsState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1000) {
          columns = 3;
        } else if (constraints.maxWidth >= 650) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 16.0;

        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        final condominiumSubtitle = state.totalCondominiums > 0
            ? '${state.activeCondominiums} ${_pluralWord(state.activeCondominiums, 'ativo', 'ativos')}'
            : null;

        final accountsSubtitle = state.totalUsers > 0
            ? '${state.activeUsers} ${_pluralWord(state.activeUsers, 'ativa', 'ativas')}'
            : null;

        final apartmentSubtitle = state.totalBlocks > 0
            ? 'em ${_pluralize(state.totalBlocks, 'bloco', 'blocos')}'
            : null;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Condomínios',
                value: '${state.totalCondominiums}',
                subtitle: condominiumSubtitle,
                icon: Icons.apartment_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Contas',
                value: '${state.totalUsers}',
                subtitle: accountsSubtitle,
                icon: Icons.people_outline,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Apartamentos',
                value: '${state.totalApartments}',
                subtitle: apartmentSubtitle,
                icon: Icons.home_work_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCondominiums(
    BuildContext context,
    AdminDetailsState state,
    bool isSmall,
  ) {
    final filtered = _filterCondominiums(state.condominiums);

    final headerTitle = Text(
      'Condomínios',
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );

    final newCondominiumButton = FilledButton.icon(
      onPressed: () {
        context.go(AppRoutes.newCondominiumPath(widget.administratorId));
      },
      icon: const Icon(Icons.add),
      label: const Text('Novo condomínio'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isSmall) ...[
          headerTitle,
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: newCondominiumButton),
        ] else
          Row(
            children: [
              Expanded(child: headerTitle),
              newCondominiumButton,
            ],
          ),
        if (state.condominiums.isNotEmpty) ...[
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              setState(() {
                _search = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar condomínio por nome ou endereço...',
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
        ],
        const SizedBox(height: 16),
        if (state.condominiums.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.apartment_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum condomínio vinculado.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cadastre um condomínio para começar a configurar blocos, apartamentos e contas.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (filtered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhum condomínio encontrado para a busca informada.',
                    ),
                  ],
                ),
              ),
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
                    _CondominiumTile(
                      item: item,
                      isSmall: isSmall,
                      onOpen: () => _openCondominium(item.condominium.id),
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

  void _openCondominium(String condominiumId) {
    context.go(
      AppRoutes.condominiumDetailsPath(
        condominiumId,
        administratorId: widget.administratorId,
      ),
    );
  }

  Future<void> _confirmAndToggleActive(AdministratorModel administrator) async {
    if (administrator.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Desativar administradora'),
            content: Text(
              'Deseja realmente desativar "${administrator.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Desativar'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) return;
    }

    final controller = ref.read(
      adminDetailsControllerProvider(widget.administratorId).notifier,
    );
    final success = await controller.toggleAdministratorActive();

    if (!mounted) return;

    final updatedState = ref.read(
      adminDetailsControllerProvider(widget.administratorId),
    );

    if (success) {
      final isActiveNow = updatedState.administrator?.active ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActiveNow
                ? 'Administradora ativada com sucesso.'
                : 'Administradora desativada com sucesso.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedState.actionError ?? 'Erro ao atualizar administradora.',
          ),
        ),
      );
    }
  }

  Future<void> _showEditAdministratorDialog(
    AdministratorModel administrator,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _EditAdministratorDialog(
          administrator: administrator,
          onSubmit: ({
            required String name,
            required String email,
            required String phone,
          }) async {
            final controller = ref.read(
              adminDetailsControllerProvider(widget.administratorId).notifier,
            );

            final success = await controller.updateAdministrator(
              name: name,
              email: email,
              phone: phone,
            );

            if (!mounted) return false;

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Administradora atualizada com sucesso.'),
                ),
              );
              return true;
            }

            final errorMessage = ref
                .read(adminDetailsControllerProvider(widget.administratorId))
                .actionError;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  errorMessage ?? 'Erro ao atualizar administradora.',
                ),
              ),
            );
            return false;
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _EditAdministratorDialog extends StatefulWidget {
  final AdministratorModel administrator;
  final Future<bool> Function({
    required String name,
    required String email,
    required String phone,
  })
  onSubmit;

  const _EditAdministratorDialog({
    required this.administrator,
    required this.onSubmit,
  });

  @override
  State<_EditAdministratorDialog> createState() =>
      _EditAdministratorDialogState();
}

class _EditAdministratorDialogState extends State<_EditAdministratorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final String _initialName;
  late final String _initialEmail;
  late final String _initialPhone;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _isSubmitting = false;
  bool _hasChanges = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _initialName = widget.administrator.name.trim();
    _initialEmail = widget.administrator.email.trim();
    _initialPhone = (widget.administrator.phone ?? '').trim();

    _nameController = TextEditingController(text: widget.administrator.name);
    _emailController = TextEditingController(text: widget.administrator.email);
    _phoneController = TextEditingController(
      text: widget.administrator.phone ?? '',
    );

    _isFormValid =
        _initialName.isNotEmpty &&
        _isValidEmail(_initialEmail) &&
        (_initialPhone.isEmpty || _isValidPhone(_initialPhone));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 13;
  }

  void _evaluateForm() {
    final currentName = _nameController.text.trim();
    final currentEmail = _emailController.text.trim();
    final currentPhone = _phoneController.text.trim();

    final valid =
        currentName.isNotEmpty &&
        _isValidEmail(currentEmail) &&
        (currentPhone.isEmpty || _isValidPhone(currentPhone));

    final changed =
        currentName != _initialName ||
        currentEmail != _initialEmail ||
        currentPhone != _initialPhone;

    if (valid != _isFormValid || changed != _hasChanges) {
      setState(() {
        _isFormValid = valid;
        _hasChanges = changed;
      });
    }
  }

  Future<void> _submit() async {
    if (!_hasChanges || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await widget.onSubmit(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_isSubmitting && _hasChanges && _isFormValid;

    return AlertDialog(
      title: const Text('Editar administradora'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _evaluateForm(),
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da administradora.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _evaluateForm(),
                decoration: const InputDecoration(
                  labelText: 'E-mail *',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';

                  if (email.isEmpty) {
                    return 'Informe o e-mail.';
                  }

                  if (!_isValidEmail(email)) {
                    return 'Informe um e-mail válido.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.phone,
                onChanged: (_) => _evaluateForm(),
                decoration: const InputDecoration(
                  labelText: 'Telefone (opcional)',
                  hintText: 'Ex.: (11) 99999-9999',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final phone = value?.trim() ?? '';

                  if (phone.isNotEmpty && !_isValidPhone(phone)) {
                    return 'Informe um telefone válido.';
                  }

                  return null;
                },
              ),
              if (!_hasChanges) ...[
                const SizedBox(height: 12),
                Text(
                  'Altere ao menos um campo para habilitar o salvamento.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canSave ? _submit : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

class _CondominiumTile extends StatelessWidget {
  final CondominiumOverviewItem item;
  final bool isSmall;
  final VoidCallback onOpen;

  const _CondominiumTile({
    required this.item,
    required this.isSmall,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final condominium = item.condominium;
    final isComplete = item.isConfigurationComplete;
    final hasAddress = condominium.address.trim().isNotEmpty;

    final metricsText =
        '${_pluralize(item.blocksCount, 'bloco', 'blocos')} • '
        '${_pluralize(item.apartmentsCount, 'apartamento', 'apartamentos')} • '
        '${_pluralize(item.usersCount, 'conta', 'contas')}';

    final pendingText = !isComplete
        ? 'Etapas pendentes: ${item.pendingSteps.join(', ')}'
        : null;

    final statusChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!condominium.active)
          Chip(
            label: const Text('Inativo'),
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
        Chip(
          label: Text(item.configurationStatusLabel),
          backgroundColor: isComplete
              ? colorScheme.secondaryContainer
              : colorScheme.tertiaryContainer,
        ),
        FilledButton.tonal(onPressed: onOpen, child: const Text('Abrir')),
      ],
    );

    if (isSmall) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.apartment_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    condominium.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (hasAddress) ...[
              const SizedBox(height: 6),
              Text(
                condominium.address,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 6),
            Text(metricsText, style: Theme.of(context).textTheme.bodyMedium),
            if (pendingText != null) ...[
              const SizedBox(height: 4),
              Text(
                pendingText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            statusChips,
          ],
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: CircleAvatar(
        child: Icon(Icons.apartment_outlined, color: colorScheme.primary),
      ),
      title: Text(
        condominium.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAddress) ...[
              Text(condominium.address),
              const SizedBox(height: 2),
            ],
            Text(metricsText),
            if (pendingText != null) ...[
              const SizedBox(height: 2),
              Text(
                pendingText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      trailing: statusChips,
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? ' ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: subtitle != null
                          ? colorScheme.onSurfaceVariant
                          : Colors.transparent,
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

String _pluralWord(int count, String singular, String plural) {
  return count == 1 ? singular : plural;
}

String _pluralize(int count, String singular, String plural) {
  return '$count ${_pluralWord(count, singular, plural)}';
}
