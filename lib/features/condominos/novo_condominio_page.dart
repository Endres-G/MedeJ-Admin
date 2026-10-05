import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NewCondominiumPage extends StatefulWidget {
  final String administratorId;

  const NewCondominiumPage({super.key, required this.administratorId});

  @override
  State<NewCondominiumPage> createState() => _NewCondominiumPageState();
}

class _NewCondominiumPageState extends State<NewCondominiumPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
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
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildSteps(context, isSmall),
              const SizedBox(height: 32),
              _buildForm(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () =>
              context.go('/administrators/${widget.administratorId}'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Administradora'),
        ),
        const SizedBox(height: 20),
        Text(
          'Novo condomínio',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Cadastre o condomínio e configure sua estrutura.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildSteps(BuildContext context, bool isSmall) {
    final steps = [
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
                          Expanded(child: Divider(indent: 8, endIndent: 8)),
                      ],
                    ),
                  );
                }),
              ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informações do condomínio',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Informe os dados básicos para começar a configuração.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do condomínio',
                  hintText: 'Ex.: Residencial Jardim',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do condomínio';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço',
                  hintText: 'Ex.: Rua das Flores, 100',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        context.go('/administrators/${widget.administratorId}'),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _continue,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continuar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Condomínio salvo. Próxima etapa: blocos.')),
    );
  }
}
