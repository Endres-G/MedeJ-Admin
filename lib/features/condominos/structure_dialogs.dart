import 'package:flutter/material.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamentos_model.dart';
import 'package:mede_ja_admin/features/blocos/bloco_model.dart';
import 'package:mede_ja_admin/features/condominos/condominio_model.dart';

Future<void> showEditCondominiumDialog({
  required BuildContext context,
  required CondominiumModel condominium,
  required Future<bool> Function({
    required String name,
    required String address,
  })
  onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _EditCondominiumDialog(
      condominium: condominium,
      onSubmit: onSubmit,
    ),
  );
}

Future<void> showEditBlockDialog({
  required BuildContext context,
  required BlockModel block,
  required bool Function(String candidateName) isDuplicateName,
  required Future<bool> Function(String name) onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _EditSingleNameDialog(
      title: 'Editar bloco',
      fieldLabel: 'Nome do bloco *',
      fieldHint: 'Ex.: Bloco A',
      fieldIcon: Icons.domain_outlined,
      initialValue: block.name,
      duplicateErrorText: 'Já existe outro bloco com este nome.',
      isDuplicateName: isDuplicateName,
      onSubmit: onSubmit,
    ),
  );
}

Future<void> showEditApartmentDialog({
  required BuildContext context,
  required ApartmentModel apartment,
  required String blockName,
  required bool Function(String candidateName) isDuplicateName,
  required Future<bool> Function(String name) onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _EditSingleNameDialog(
      title: 'Editar apartamento ($blockName)',
      fieldLabel: 'Identificação / Número do apartamento *',
      fieldHint: 'Ex.: 101',
      fieldIcon: Icons.home_work_outlined,
      initialValue: apartment.name,
      duplicateErrorText: 'Já existe outro apartamento com este número no bloco.',
      isDuplicateName: isDuplicateName,
      onSubmit: onSubmit,
    ),
  );
}

Future<bool> showConfirmStatusToggleDialog({
  required BuildContext context,
  required String entityLabel,
  required String entityName,
  required bool currentlyActive,
}) async {
  final actionLabel = currentlyActive ? 'Desativar' : 'Ativar';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('$actionLabel $entityLabel'),
        content: Text(
          currentlyActive
              ? 'Deseja realmente desativar "$entityName"?'
              : 'Deseja reativar "$entityName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(actionLabel),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

class _EditCondominiumDialog extends StatefulWidget {
  final CondominiumModel condominium;
  final Future<bool> Function({
    required String name,
    required String address,
  })
  onSubmit;

  const _EditCondominiumDialog({
    required this.condominium,
    required this.onSubmit,
  });

  @override
  State<_EditCondominiumDialog> createState() => _EditCondominiumDialogState();
}

class _EditCondominiumDialogState extends State<_EditCondominiumDialog> {
  final _formKey = GlobalKey<FormState>();
  late final String _initialName;
  late final String _initialAddress;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;

  bool _isSubmitting = false;
  bool _hasChanges = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _initialName = widget.condominium.name.trim();
    _initialAddress = widget.condominium.address.trim();
    _nameController = TextEditingController(text: widget.condominium.name);
    _addressController = TextEditingController(
      text: widget.condominium.address,
    );
    _isFormValid = _initialName.length >= 3 && _initialAddress.length >= 5;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _evaluate() {
    final currentName = _nameController.text.trim();
    final currentAddress = _addressController.text.trim();

    final valid = currentName.length >= 3 && currentAddress.length >= 5;
    final changed =
        currentName != _initialName || currentAddress != _initialAddress;

    if (valid != _isFormValid || changed != _hasChanges) {
      setState(() {
        _isFormValid = valid;
        _hasChanges = changed;
      });
    }
  }

  Future<void> _submit() async {
    if (!_hasChanges || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final ok = await widget.onSubmit(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
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
    final canSave = !_isSubmitting && _hasChanges && _isFormValid;

    return AlertDialog(
      title: const Text('Editar condomínio'),
      content: SizedBox(
        width: 480,
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
                onChanged: (_) => _evaluate(),
                decoration: const InputDecoration(
                  labelText: 'Nome do condomínio *',
                  prefixIcon: Icon(Icons.apartment_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Informe o nome do condomínio.';
                  }
                  if (trimmed.length < 3) {
                    return 'O nome deve ter ao menos 3 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                enabled: !_isSubmitting,
                maxLines: 2,
                onChanged: (_) => _evaluate(),
                decoration: const InputDecoration(
                  labelText: 'Endereço *',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Informe o endereço do condomínio.';
                  }
                  if (trimmed.length < 5) {
                    return 'Informe um endereço válido.';
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

class _EditSingleNameDialog extends StatefulWidget {
  final String title;
  final String fieldLabel;
  final String fieldHint;
  final IconData fieldIcon;
  final String initialValue;
  final String duplicateErrorText;
  final bool Function(String candidateName) isDuplicateName;
  final Future<bool> Function(String name) onSubmit;

  const _EditSingleNameDialog({
    required this.title,
    required this.fieldLabel,
    required this.fieldHint,
    required this.fieldIcon,
    required this.initialValue,
    required this.duplicateErrorText,
    required this.isDuplicateName,
    required this.onSubmit,
  });

  @override
  State<_EditSingleNameDialog> createState() => _EditSingleNameDialogState();
}

class _EditSingleNameDialogState extends State<_EditSingleNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final String _initialTrimmed;
  late final TextEditingController _controller;

  bool _isSubmitting = false;
  bool _hasChanges = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _initialTrimmed = widget.initialValue.trim();
    _controller = TextEditingController(text: widget.initialValue);
    _isFormValid = _initialTrimmed.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _evaluate() {
    final current = _controller.text.trim();
    final changed = current != _initialTrimmed;
    final valid = current.isNotEmpty && !widget.isDuplicateName(current);

    if (changed != _hasChanges || valid != _isFormValid) {
      setState(() {
        _hasChanges = changed;
        _isFormValid = valid;
      });
    }
  }

  Future<void> _submit() async {
    if (!_hasChanges || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final ok = await widget.onSubmit(_controller.text.trim());
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
    final canSave = !_isSubmitting && _hasChanges && _isFormValid;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _controller,
                enabled: !_isSubmitting,
                autofocus: true,
                onChanged: (_) => _evaluate(),
                decoration: InputDecoration(
                  labelText: widget.fieldLabel,
                  hintText: widget.fieldHint,
                  prefixIcon: Icon(widget.fieldIcon),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Este campo é obrigatório.';
                  }
                  if (widget.isDuplicateName(trimmed)) {
                    return widget.duplicateErrorText;
                  }
                  return null;
                },
              ),
              if (!_hasChanges) ...[
                const SizedBox(height: 12),
                Text(
                  'Altere o valor atual para habilitar o salvamento.',
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
