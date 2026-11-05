import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/contas/accounts_controller.dart';
import 'package:mede_ja_admin/features/users/user_credentials_dialog.dart';
import 'package:mede_ja_admin/features/users/user_provisioning_datasrc.dart';

class NewCondominiumUserPage extends ConsumerStatefulWidget {
  final String condominiumId;
  final String? administratorId;

  const NewCondominiumUserPage({
    super.key,
    required this.condominiumId,
    this.administratorId,
  });

  @override
  ConsumerState<NewCondominiumUserPage> createState() =>
      _NewCondominiumUserPageState();
}

class _NewCondominiumUserPageState
    extends ConsumerState<NewCondominiumUserPage> {
  static const String _noApartmentSentinel = '__NONE__';

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late final TextEditingController _tempPasswordController;

  String? _selectedApartmentId;
  bool _active = true;
  bool _obscurePassword = false;

  CondominiumScope get _scope => CondominiumScope(
    condominiumId: widget.condominiumId,
    administratorId: widget.administratorId,
  );

  String _usersRoute(CondominiumDetailsState state) {
    final effectiveAdminId =
        state.resolvedAdministratorId ?? widget.administratorId;
    return AppRoutes.condominiumUsersPath(
      widget.condominiumId,
      administratorId: effectiveAdminId,
    );
  }

  @override
  void initState() {
    super.initState();
    _tempPasswordController = TextEditingController(
      text: generateTemporaryPassword(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _tempPasswordController.dispose();
    super.dispose();
  }

  void _regeneratePassword() {
    setState(() {
      _tempPasswordController.text = generateTemporaryPassword();
      _obscurePassword = false;
    });
  }

  Future<void> _copyDraftPassword() async {
    final pwd = _tempPasswordController.text;
    if (pwd.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: pwd));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Senha temporária copiada para a área de transferência.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final condoState = ref.watch(condominiumDetailsControllerProvider(_scope));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        if (condoState.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (condoState.error != null && condoState.condominium == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          condoState.error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  context.go(_usersRoute(condoState)),
                              child: const Text('Voltar'),
                            ),
                            FilledButton.icon(
                              onPressed: () => ref
                                  .read(
                                    condominiumDetailsControllerProvider(
                                      _scope,
                                    ).notifier,
                                  )
                                  .load(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, condoState),
                  const SizedBox(height: 24),
                  _buildCondominiumAccountGuidance(context, condoState),
                  const SizedBox(height: 20),
                  _buildForm(context, condoState, isSmall),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, CondominiumDetailsState condoState) {
    final condoName = condoState.condominium?.name.trim() ?? '';
    final backLabel = condoName.isNotEmpty
        ? 'Voltar para Contas de $condoName'
        : 'Voltar para Contas e usuários';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: condoState.isSaving
              ? null
              : () => context.go(_usersRoute(condoState)),
          icon: const Icon(Icons.arrow_back),
          label: Text(backLabel),
        ),
        const SizedBox(height: 20),
        Text(
          'Nova conta de acesso',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          condoName.isNotEmpty
              ? 'Crie uma conta vinculada ao condomínio $condoName com senha temporária de primeiro acesso.'
              : 'Crie uma conta de acesso vinculada a este condomínio.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildCondominiumAccountGuidance(
    BuildContext context,
    CondominiumDetailsState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.users.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_outlined,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Este condomínio ainda não possui conta vinculada. Esta será a conta operacional principal utilizada para executar as leituras no aplicativo MedeJá.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    final existingEmails = state.users
        .take(3)
        .map((u) => u.email)
        .join(', ');
    final moreSuffix = state.users.length > 3
        ? ' e +${state.users.length - 3}'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.users.length == 1
                      ? 'Este condomínio já possui 1 conta vinculada ($existingEmails).'
                      : 'Este condomínio já possui ${state.users.length} contas vinculadas ($existingEmails$moreSuffix).',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'O padrão operacional é utilizar 1 conta por condomínio, mas você pode adicionar contas extras caso mais de um responsável realize as leituras.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    CondominiumDetailsState condoState,
    bool isSmall,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final allApartments = condoState.allApartments;
    final validApartmentIds = allApartments
        .map((item) => item.apartment.id)
        .toSet();
    final dropdownValue =
        (_selectedApartmentId != null &&
            validApartmentIds.contains(_selectedApartmentId))
        ? _selectedApartmentId!
        : _noApartmentSentinel;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 20 : 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dados do usuário',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'A conta será provisionada no Firebase Authentication sem desconectar sua sessão administrativa.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (condoState.actionError != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          condoState.actionError!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                enabled: !condoState.isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome completo *',
                  hintText: 'Ex.: João Silva',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome completo.';
                  }
                  if (value.trim().length < 3) {
                    return 'Informe um nome com pelo menos 3 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                enabled: !condoState.isSaving,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail de acesso *',
                  hintText: 'Ex.: operador.condominio@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o e-mail de acesso.';
                  }
                  final email = value.trim().toLowerCase();
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(email)) {
                    return 'Informe um e-mail válido.';
                  }
                  final controller = ref.read(
                    condominiumDetailsControllerProvider(_scope).notifier,
                  );
                  if (controller.hasUserWithEmail(email)) {
                    return 'Este e-mail já está vinculado a este condomínio.';
                  }
                  return null;
                },
              ),
              if (allApartments.isNotEmpty) ...[
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  key: ValueKey(dropdownValue),
                  initialValue: dropdownValue,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Escopo no condomínio (opcional)',
                    helperText:
                        'Por padrão, a conta tem vínculo geral com o condomínio.',
                    prefixIcon: Icon(Icons.home_work_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: _noApartmentSentinel,
                      child: Text('Acesso geral ao condomínio (recomendado)'),
                    ),
                    ...allApartments.map(
                      (item) => DropdownMenuItem<String>(
                        value: item.apartment.id,
                        child: Text(
                          '${item.block.name} • Apto ${item.apartment.name}',
                        ),
                      ),
                    ),
                  ],
                  onChanged: condoState.isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _selectedApartmentId =
                                (value == null || value == _noApartmentSentinel)
                                ? null
                                : value;
                          });
                        },
                ),
              ],
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Senha temporária de primeiro acesso',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gerada com entropia criptográfica. O usuário deverá redefinir a senha ao entrar no app MedeJá.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: condoState.isSaving ? null : _regeneratePassword,
                    icon: const Icon(Icons.autorenew, size: 18),
                    label: const Text('Gerar outra senha'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tempPasswordController,
                enabled: !condoState.isSaving,
                obscureText: _obscurePassword,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  labelText: 'Senha temporária *',
                  helperText:
                      'Mínimo de 8 caracteres com letras e números. Não é armazenada no banco de dados.',
                  prefixIcon: const Icon(Icons.key_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Copiar senha temporária',
                        onPressed: _copyDraftPassword,
                        icon: const Icon(Icons.copy_outlined),
                      ),
                      IconButton(
                        tooltip: _obscurePassword
                            ? 'Mostrar senha'
                            : 'Ocultar senha',
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                validator: validateTemporaryPassword,
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Conta ativa'),
                subtitle: const Text(
                  'Permite que o usuário faça login no aplicativo MedeJá.',
                ),
                value: _active,
                onChanged: condoState.isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _active = value;
                        });
                      },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),
              _buildActions(context, condoState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    CondominiumDetailsState condoState,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton(
          onPressed: condoState.isSaving
              ? null
              : () => context.go(_usersRoute(condoState)),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: condoState.isSaving
              ? null
              : () => _createUser(condoState),
          icon: condoState.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add_outlined),
          label: Text(
            condoState.isSaving ? 'Criando conta...' : 'Criar conta',
          ),
        ),
      ],
    );
  }

  Future<void> _createUser(CondominiumDetailsState condoState) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ref.read(
      condominiumDetailsControllerProvider(_scope).notifier,
    );

    final credentials = await controller.provisionCondominiumUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      temporaryPassword: _tempPasswordController.text,
      apartmentId: _selectedApartmentId,
      active: _active,
    );

    if (!mounted) return;

    if (credentials == null) {
      return;
    }

    ref.invalidate(accountsControllerProvider);

    final destination = _usersRoute(
      ref.read(condominiumDetailsControllerProvider(_scope)),
    );

    await showProvisionedCredentialsDialog(
      context: context,
      credentials: credentials,
    );

    if (!mounted) return;
    context.go(destination);
  }
}
