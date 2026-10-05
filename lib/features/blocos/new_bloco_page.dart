import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';

class NewBlockPage extends StatefulWidget {
  final String condominiumId;

  const NewBlockPage({super.key, required this.condominiumId});

  @override
  State<NewBlockPage> createState() => _NewBlockPageState();
}

class _NewBlockPageState extends State<NewBlockPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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
              _buildForm(context, isSmall),
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
          onPressed: () {
            context.go(
              AppRoutes.condominiumBlocks.replaceFirst(
                ':condominiumId',
                widget.condominiumId,
              ),
            );
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Blocos'),
        ),
        const SizedBox(height: 20),
        Text(
          'Novo bloco',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Cadastre um novo bloco para o condomínio.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isSmall) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 20 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informações do bloco',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Informe o nome ou identificação do bloco.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome do bloco',
                  hintText: 'Ex.: Bloco A',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.domain_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do bloco';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      context.go(
                        AppRoutes.condominiumBlocks.replaceFirst(
                          ':condominiumId',
                          widget.condominiumId,
                        ),
                      );
                    },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _createBlock,
                    icon: const Icon(Icons.check),
                    label: const Text('Criar bloco'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createBlock() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bloco "$name" criado com sucesso.')),
    );

    context.go(
      AppRoutes.condominiumBlocks.replaceFirst(
        ':condominiumId',
        widget.condominiumId,
      ),
    );
  }
}
