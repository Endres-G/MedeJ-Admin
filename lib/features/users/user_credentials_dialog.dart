import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mede_ja_admin/features/auth/account_role_datasrc.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/contas/accounts_controller.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';
import 'package:mede_ja_admin/features/users/user_provisioning_datasrc.dart';

Future<void> showProvisionedCredentialsDialog({
  required BuildContext context,
  required ProvisionedUserCredentials credentials,
  String? customTitle,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ProvisionedCredentialsDialog(
      credentials: credentials,
      customTitle: customTitle,
    ),
  );
}

Future<void> showEditUserDialog({
  required BuildContext context,
  required UserModel user,
  bool isCurrentSessionUser = false,
  List<ApartmentWithBlockItem>? availableApartments,
  required Future<bool> Function({
    required String name,
    required UserRole role,
    String? apartmentId,
    bool clearApartmentId,
  })
  onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _EditUserDialog(
      user: user,
      isCurrentSessionUser: isCurrentSessionUser,
      availableApartments: availableApartments,
      onSubmit: onSubmit,
    ),
  );
}

Future<bool> showConfirmPasswordResetDialog({
  required BuildContext context,
  required UserModel user,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Enviar redefinição de senha'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deseja enviar um link seguro de redefinição de senha para "${user.name}"?',
              ),
              const SizedBox(height: 12),
              SelectableText(
                user.email,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'O Firebase Authentication enviará um e-mail oficial com link temporário para que o usuário defina uma nova senha de acesso.',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.mark_email_read_outlined, size: 18),
            label: const Text('Enviar e-mail'),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

class _ProvisionedCredentialsDialog extends StatefulWidget {
  final ProvisionedUserCredentials credentials;
  final String? customTitle;

  const _ProvisionedCredentialsDialog({
    required this.credentials,
    this.customTitle,
  });

  @override
  State<_ProvisionedCredentialsDialog> createState() =>
      _ProvisionedCredentialsDialogState();
}

class _ProvisionedCredentialsDialogState
    extends State<_ProvisionedCredentialsDialog> {
  bool _copiedPassword = false;
  bool _copiedSummary = false;

  Future<void> _copyPassword() async {
    await Clipboard.setData(
      ClipboardData(text: widget.credentials.temporaryPassword),
    );
    if (!mounted) return;
    setState(() {
      _copiedPassword = true;
    });
  }

  Future<void> _copyFullSummary() async {
    await Clipboard.setData(
      ClipboardData(text: widget.credentials.buildShareableSummary()),
    );
    if (!mounted) return;
    setState(() {
      _copiedSummary = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final creds = widget.credentials;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.customTitle ?? 'Conta criada com sucesso'),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.security_outlined,
                      size: 20,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Repasse esta senha temporária ao usuário para o primeiro acesso. Enquanto a troca de senha não for realizada, você pode consultar ou regenerar a senha neste painel.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _CredentialInfoRow(
                label: 'Perfil (Role)',
                value: creds.user.isAdmin
                    ? 'Administrador (Acesso ao Painel Admin)'
                    : 'Comum / Operacional (Apenas App Mobile)',
              ),
              const SizedBox(height: 8),
              _CredentialInfoRow(
                label: creds.condominiumId.trim().isNotEmpty
                    ? 'Condomínio'
                    : 'Escopo',
                value: creds.condominiumName,
              ),
              if (creds.administratorName != null &&
                  creds.administratorName!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _CredentialInfoRow(
                  label: 'Administradora',
                  value: creds.administratorName!,
                ),
              ],
              const SizedBox(height: 8),
              _CredentialInfoRow(label: 'Usuário', value: creds.user.name),
              const SizedBox(height: 8),
              _CredentialInfoRow(label: 'E-mail', value: creds.user.email),
              const SizedBox(height: 18),
              Text(
                'Senha temporária de primeiro acesso',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.primary),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        creds.temporaryPassword,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: _copyPassword,
                      icon: Icon(
                        _copiedPassword ? Icons.check : Icons.copy,
                        size: 18,
                      ),
                      label: Text(_copiedPassword ? 'Copiada!' : 'Copiar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                creds.user.isAdmin
                    ? 'Esta conta possui permissão de Administrador e pode autenticar no painel web MedeJá Admin.'
                    : 'Esta conta possui perfil Comum/Operacional: ela é bloqueada no painel Admin e deve ser usada exclusivamente no aplicativo mobile MedeJá (onde redefinirá a senha no 1º login).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: _copyFullSummary,
          icon: Icon(_copiedSummary ? Icons.check : Icons.share_outlined),
          label: Text(
            _copiedSummary
                ? 'Dados de acesso copiados!'
                : 'Copiar dados de acesso',
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Concluir'),
        ),
      ],
    );
  }
}

class _CredentialInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CredentialInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final UserModel user;
  final bool isCurrentSessionUser;
  final List<ApartmentWithBlockItem>? availableApartments;
  final Future<bool> Function({
    required String name,
    required UserRole role,
    String? apartmentId,
    bool clearApartmentId,
  })
  onSubmit;

  const _EditUserDialog({
    required this.user,
    required this.isCurrentSessionUser,
    required this.availableApartments,
    required this.onSubmit,
  });

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late UserRole _selectedRole;
  String? _selectedApartmentId;
  bool _isSubmitting = false;

  static const String _noApartmentSentinel = '__NONE__';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _selectedRole = widget.user.role;
    _selectedApartmentId = widget.user.apartmentId;
    _nameController.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onChanged);
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final nameChanged = _nameController.text.trim() != widget.user.name.trim();
    final roleChanged = _selectedRole != widget.user.role;
    if (widget.availableApartments == null) {
      return nameChanged || roleChanged;
    }
    final initialApt =
        (widget.user.apartmentId == null || widget.user.apartmentId!.isEmpty)
        ? null
        : widget.user.apartmentId;
    final currentApt =
        (_selectedApartmentId == null || _selectedApartmentId!.isEmpty)
        ? null
        : _selectedApartmentId;
    return nameChanged || roleChanged || initialApt != currentApt;
  }

  bool get _isValid => _nameController.text.trim().length >= 3;

  Future<void> _submit() async {
    if (!_hasChanges || !_isValid || _isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final ok = await widget.onSubmit(
      name: _nameController.text.trim(),
      role: _selectedRole,
      apartmentId: _selectedApartmentId,
      clearApartmentId: _selectedApartmentId == null,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final apartments = widget.availableApartments;
    final validApartmentIds = apartments?.map((a) => a.apartment.id).toSet();
    final dropdownValue =
        (_selectedApartmentId != null &&
            validApartmentIds != null &&
            validApartmentIds.contains(_selectedApartmentId))
        ? _selectedApartmentId!
        : _noApartmentSentinel;

    return AlertDialog(
      title: const Text('Editar conta e permissões'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Informe um nome com pelo menos 3 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.user.email,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'E-mail de acesso (identificador da conta)',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  key: ValueKey(_selectedRole),
                  initialValue: _selectedRole,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Perfil de acesso (Role) *',
                    helperText: widget.isCurrentSessionUser
                        ? 'Você não pode remover o perfil Admin da sua própria conta em uso.'
                        : _selectedRole.description,
                    helperMaxLines: 2,
                    prefixIcon: Icon(
                      _selectedRole.isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.smartphone_outlined,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.user,
                      child: Text('Comum / Operacional (App de Leituras)'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Administrador (Painel MedeJá Admin)'),
                    ),
                  ],
                  onChanged: (_isSubmitting || widget.isCurrentSessionUser)
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                ),
                if (_selectedRole.isAdmin && !widget.user.isAdmin) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Atenção: ao salvar como Administrador, esta conta passará a ter acesso completo ao painel MedeJá Admin.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
                if (apartments != null && apartments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(dropdownValue),
                    initialValue: dropdownValue,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Vínculo de unidade (opcional)',
                      prefixIcon: Icon(Icons.home_work_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: _noApartmentSentinel,
                        child: Text('Acesso geral ao condomínio (padrão)'),
                      ),
                      ...apartments.map(
                        (item) => DropdownMenuItem<String>(
                          value: item.apartment.id,
                          child: Text(
                            '${item.block.name} • Apto ${item.apartment.name}',
                          ),
                        ),
                      ),
                    ],
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedApartmentId =
                                  (value == null ||
                                      value == _noApartmentSentinel)
                                  ? null
                                  : value;
                            });
                          },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_hasChanges && _isValid && !_isSubmitting)
              ? _submit
              : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar alterações'),
        ),
      ],
    );
  }
}

Future<bool> showConfirmDeleteAccountDialog({
  required BuildContext context,
  required String userName,
  required String userEmail,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      final colorScheme = Theme.of(dialogCtx).colorScheme;
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error),
            const SizedBox(width: 10),
            const Expanded(child: Text('Excluir conta')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deseja realmente excluir permanentemente a conta de "$userName"?'),
              const SizedBox(height: 8),
              SelectableText(
                userEmail,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Esta ação desvinculará a conta dos condomínios e revogará os acessos ao aplicativo mobile e ao painel administrativo.',
                style: Theme.of(dialogCtx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Excluir conta'),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

Future<bool> showConfirmUnlinkAccountDialog({
  required BuildContext context,
  required String userName,
  required String condominiumName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Desvincular do condomínio'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja desvincular a conta de "$userName" do condomínio "$condominiumName"?',
            ),
            const SizedBox(height: 12),
            Text(
              'A conta continuará existindo no sistema como conta avulsa/sem condomínio, podendo ser vinculada a qualquer outro condomínio no futuro.',
              style: Theme.of(dialogCtx).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: const Text('Desvincular'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<String?> showRegenerateTemporaryPasswordDialog({
  required BuildContext context,
  required String userName,
  required String userEmail,
}) async {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _RegeneratePasswordDialog(
      userName: userName,
      userEmail: userEmail,
    ),
  );
}

class _RegeneratePasswordDialog extends StatefulWidget {
  final String userName;
  final String userEmail;

  const _RegeneratePasswordDialog({
    required this.userName,
    required this.userEmail,
  });

  @override
  State<_RegeneratePasswordDialog> createState() =>
      _RegeneratePasswordDialogState();
}

class _RegeneratePasswordDialogState extends State<_RegeneratePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _passwordController;
  bool _obscurePassword = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(
      text: generateTemporaryPassword(),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _regenerate() {
    setState(() {
      _passwordController.text = generateTemporaryPassword();
      _obscurePassword = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.password_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('Regenerar senha temporária')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Defina uma nova senha temporária de primeiro acesso para:'),
              const SizedBox(height: 6),
              Text(
                '${widget.userName} (${widget.userEmail})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  labelText: 'Nova senha temporária *',
                  helperText: 'Mínimo de 8 caracteres com letras e números.',
                  prefixIcon: const Icon(Icons.key_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Gerar outra senha',
                        onPressed: _regenerate,
                        icon: const Icon(Icons.autorenew),
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
              const SizedBox(height: 10),
              Text(
                'Ao confirmar, a senha temporária será atualizada e exibida para você copiar e repassar ao usuário.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _passwordController.text.trim());
            }
          },
          child: const Text('Regenerar senha'),
        ),
      ],
    );
  }
}

Future<AccountRoleProfile?> showSelectAccountToLinkDialog({
  required BuildContext context,
  required String condominiumName,
  required List<AccountRoleProfile> availableAccounts,
}) async {
  return showDialog<AccountRoleProfile>(
    context: context,
    builder: (ctx) => _SelectAccountToLinkDialog(
      condominiumName: condominiumName,
      availableAccounts: availableAccounts,
    ),
  );
}

class _SelectAccountToLinkDialog extends StatefulWidget {
  final String condominiumName;
  final List<AccountRoleProfile> availableAccounts;

  const _SelectAccountToLinkDialog({
    required this.condominiumName,
    required this.availableAccounts,
  });

  @override
  State<_SelectAccountToLinkDialog> createState() =>
      _SelectAccountToLinkDialogState();
}

class _SelectAccountToLinkDialogState
    extends State<_SelectAccountToLinkDialog> {
  AccountRoleProfile? _selected;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();
    final filtered = widget.availableAccounts.where((a) {
      if (query.isEmpty) return true;
      return a.name.toLowerCase().contains(query) ||
          a.email.toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.link_outlined),
          const SizedBox(width: 10),
          Expanded(child: Text('Vincular conta a ${widget.condominiumName}')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecione uma conta existente sem vínculo para associar ao condomínio:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou e-mail...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Nenhuma conta disponível para vinculação.'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (ctx, index) {
                    final item = filtered[index];
                    final isSelected = _selected?.uid == item.uid;
                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      selected: isSelected,
                      selectedTileColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.35),
                      leading: CircleAvatar(
                        child: Text(
                          item.name.isNotEmpty
                              ? item.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${item.email} • ${item.role.shortLabel}'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selected = item;
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          child: const Text('Vincular conta'),
        ),
      ],
    );
  }
}

Future<CondominiumAccountGroup?> showSelectCondominiumToLinkDialog({
  required BuildContext context,
  required String accountName,
  required List<CondominiumAccountGroup> condominiumGroups,
}) async {
  return showDialog<CondominiumAccountGroup>(
    context: context,
    builder: (ctx) => _SelectCondominiumToLinkDialog(
      accountName: accountName,
      condominiumGroups: condominiumGroups,
    ),
  );
}

class _SelectCondominiumToLinkDialog extends StatefulWidget {
  final String accountName;
  final List<CondominiumAccountGroup> condominiumGroups;

  const _SelectCondominiumToLinkDialog({
    required this.accountName,
    required this.condominiumGroups,
  });

  @override
  State<_SelectCondominiumToLinkDialog> createState() =>
      _SelectCondominiumToLinkDialogState();
}

class _SelectCondominiumToLinkDialogState
    extends State<_SelectCondominiumToLinkDialog> {
  CondominiumAccountGroup? _selected;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();
    final filtered = widget.condominiumGroups.where((g) {
      if (query.isEmpty) return true;
      return g.condominium.name.toLowerCase().contains(query) ||
          g.administrator.name.toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.apartment_outlined),
          const SizedBox(width: 10),
          Expanded(child: Text('Vincular "${widget.accountName}"')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha o condomínio ao qual esta conta será vinculada:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Buscar por condomínio ou administradora...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Nenhum condomínio encontrado.'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (ctx, index) {
                    final item = filtered[index];
                    final isSelected =
                        _selected?.condominium.id == item.condominium.id &&
                        _selected?.administrator.id == item.administrator.id;
                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      selected: isSelected,
                      selectedTileColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.35),
                      leading: const CircleAvatar(
                        child: Icon(Icons.apartment_outlined, size: 20),
                      ),
                      title: Text(
                        item.condominium.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${item.administrator.name} • ${_pluralAccounts(item.totalUsers)}',
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selected = item;
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          child: const Text('Vincular a este condomínio'),
        ),
      ],
    );
  }

  String _pluralAccounts(int count) {
    if (count == 0) return 'Sem contas';
    if (count == 1) return '1 conta';
    return '$count contas';
  }
}
