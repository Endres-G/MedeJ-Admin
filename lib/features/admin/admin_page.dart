import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/admin/admin_model.dart';
import 'package:mede_ja_admin/features/admin/admin_repo.dart';

class AdministratorsPage extends StatefulWidget {
  const AdministratorsPage({super.key});

  @override
  State<AdministratorsPage> createState() => _AdministratorsPageState();
}

class _AdministratorsPageState extends State<AdministratorsPage> {
  final AdministratorRepository _repository = AdministratorRepository();

  List<AdministratorModel> _administrators = [];

  String _search = '';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdministrators();
  }

  Future<void> _loadAdministrators() async {
    try {
      debugPrint('🔵 [ADMIN] Carregando administradoras...');

      final administrators = await _repository.getAdministrators();

      debugPrint(
        '🟢 [ADMIN] ${administrators.length} administradoras encontradas.',
      );

      if (!mounted) return;

      setState(() {
        _administrators = administrators;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('🔴 [ADMIN] Erro ao carregar administradoras: $e');
      debugPrint('🔴 [ADMIN] StackTrace:\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  List<AdministratorModel> get _filteredAdministrators {
    if (_search.trim().isEmpty) {
      return _administrators;
    }

    final search = _search.toLowerCase();

    return _administrators.where((administrator) {
      return administrator.name.toLowerCase().contains(search) ||
          administrator.email.toLowerCase().contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isSmall),

              const SizedBox(height: 24),

              _buildSearch(context),

              const SizedBox(height: 24),

              _buildSummary(context),

              const SizedBox(height: 24),

              _buildAdministratorsList(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmall) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Administradoras',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Gerencie as administradoras e seus condomínios.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );

    final button = FilledButton.icon(
      onPressed: _showCreateAdministratorDialog,
      icon: const Icon(Icons.add),
      label: const Text('Nova administradora'),
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 16), button],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [title, button],
    );
  }

  Widget _buildSearch(BuildContext context) {
    return TextField(
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Buscar administradora...',
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
    );
  }

  Widget _buildSummary(BuildContext context) {
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

        final total = _administrators.length;

        final active = _administrators.where((item) => item.active).length;

        final inactive = total - active;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Total',
                value: '$total',
                icon: Icons.business_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Ativas',
                value: '$active',
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Inativas',
                value: '$inactive',
                icon: Icons.pause_circle_outline,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdministratorsList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final administrators = _filteredAdministrators;

    if (administrators.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                const Text('Nenhuma administradora encontrada.'),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: administrators.map((administrator) {
          final index = administrators.indexOf(administrator);

          return Column(
            children: [
              _AdministratorTile(
                administrator: administrator,
                onOpen: () => _openAdministrator(administrator),
                onToggle: () => _toggleAdministrator(administrator),
              ),
              if (index < administrators.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openAdministrator(AdministratorModel administrator) {
    context.go(AppRoutes.administratorDetailsPath(administrator.id));
  }

  Future<void> _toggleAdministrator(AdministratorModel administrator) async {
    final updated = administrator.copyWith(active: !administrator.active);

    try {
      await _repository.updateAdministrator(updated);

      if (!mounted) return;

      setState(() {
        final index = _administrators.indexWhere(
          (item) => item.id == administrator.id,
        );

        if (index != -1) {
          _administrators[index] = updated;
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar administradora.')),
      );
    }
  }

  Future<void> _showCreateAdministratorDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _CreateAdministratorDialog(
          onSubmit: ({
            required String name,
            required String email,
            required String phone,
          }) async {
            try {
              debugPrint('🟡 [ADMIN CREATE] Criando administradora...');

              final administrator = AdministratorModel(
                id: '',
                name: name,
                email: email,
                phone: phone.isEmpty ? null : phone,
                active: true,
              );

              final id = await _repository.createAdministrator(administrator);

              debugPrint('🟢 [ADMIN CREATE] Criada com ID: $id');

              if (!mounted) return true;

              await _loadAdministrators();

              if (!mounted) return true;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Administradora criada com sucesso.'),
                ),
              );
              return true;
            } catch (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao criar administradora.'),
                  ),
                );
              }
              return false;
            }
          },
        );
      },
    );
  }
}

class _CreateAdministratorDialog extends StatefulWidget {
  final Future<bool> Function({
    required String name,
    required String email,
    required String phone,
  })
  onSubmit;

  const _CreateAdministratorDialog({required this.onSubmit});

  @override
  State<_CreateAdministratorDialog> createState() =>
      _CreateAdministratorDialogState();
}

class _CreateAdministratorDialogState
    extends State<_CreateAdministratorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;
  bool _isFormValid = false;

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
    final valid =
        _nameController.text.trim().isNotEmpty &&
        _isValidEmail(_emailController.text.trim()) &&
        (_phoneController.text.trim().isEmpty ||
            _isValidPhone(_phoneController.text.trim()));

    if (valid != _isFormValid) {
      setState(() {
        _isFormValid = valid;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
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
    return AlertDialog(
      title: const Text('Nova administradora'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _evaluateForm(),
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  hintText: 'Ex.: Administradora ABC',
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
                  hintText: 'contato@empresa.com',
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
          onPressed: _isSubmitting || !_isFormValid ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar'),
        ),
      ],
    );
  }
}

class _AdministratorTile extends StatelessWidget {
  final AdministratorModel administrator;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  const _AdministratorTile({
    required this.administrator,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: CircleAvatar(
        child: Icon(
          Icons.business_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        administrator.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(administrator.email),
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            label: Text(administrator.active ? 'Ativa' : 'Inativa'),
            backgroundColor: administrator.active
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          IconButton(
            tooltip: administrator.active ? 'Desativar' : 'Ativar',
            onPressed: onToggle,
            icon: Icon(
              administrator.active
                  ? Icons.toggle_on_outlined
                  : Icons.toggle_off_outlined,
            ),
          ),
          FilledButton.tonal(onPressed: onOpen, child: const Text('Abrir')),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
