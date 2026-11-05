import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mede_ja_admin/features/condominos/condominium_details_controller.dart';
import 'package:mede_ja_admin/features/users/user_model.dart';
import 'package:mede_ja_admin/features/users/user_provisioning_datasrc.dart';

Future<void> showProvisionedCredentialsDialog({
  required BuildContext context,
  required ProvisionedUserCredentials credentials,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ProvisionedCredentialsDialog(credentials: credentials),
  );
}

Future<void> showEditUserDialog({
  required BuildContext context,
  required UserModel user,
  List<ApartmentWithBlockItem>? availableApartments,
  required Future<bool> Function({
    required String name,
    String? apartmentId,
    bool clearApartmentId,
  })
  onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _EditUserDialog(
      user: user,
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

  const _ProvisionedCredentialsDialog({required this.credentials});

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
          const Expanded(child: Text('Conta criada com sucesso')),
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
                        'Copie a senha temporária agora. Por segurança, ela não é salva no banco de dados e não poderá ser visualizada novamente após fechar esta janela.',
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
                label: 'Condomínio',
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
                'Como funciona o primeiro acesso: ao entrar no aplicativo MedeJá com esta senha temporária, a conta estará marcada para redefinição obrigatória de senha no primeiro login.',
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
  final List<ApartmentWithBlockItem>? availableApartments;
  final Future<bool> Function({
    required String name,
    String? apartmentId,
    bool clearApartmentId,
  })
  onSubmit;

  const _EditUserDialog({
    required this.user,
    required this.availableApartments,
    required this.onSubmit,
  });

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _selectedApartmentId;
  bool _isSubmitting = false;

  static const String _noApartmentSentinel = '__NONE__';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
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
    if (widget.availableApartments == null) {
      return nameChanged;
    }
    final initialApt =
        (widget.user.apartmentId == null || widget.user.apartmentId!.isEmpty)
        ? null
        : widget.user.apartmentId;
    final currentApt =
        (_selectedApartmentId == null || _selectedApartmentId!.isEmpty)
        ? null
        : _selectedApartmentId;
    return nameChanged || initialApt != currentApt;
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
    final apartments = widget.availableApartments;
    final validApartmentIds = apartments
        ?.map((a) => a.apartment.id)
        .toSet();
    final dropdownValue =
        (_selectedApartmentId != null &&
            validApartmentIds != null &&
            validApartmentIds.contains(_selectedApartmentId))
        ? _selectedApartmentId!
        : _noApartmentSentinel;

    return AlertDialog(
      title: const Text('Editar conta de usuário'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                                (value == null || value == _noApartmentSentinel)
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
