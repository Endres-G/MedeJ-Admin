import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';

class NewApartmentPage extends StatefulWidget {
  final String condominiumId;

  const NewApartmentPage({super.key, required this.condominiumId});

  @override
  State<NewApartmentPage> createState() => _NewApartmentPageState();
}

class _NewApartmentPageState extends State<NewApartmentPage> {
  final _formKey = GlobalKey<FormState>();

  bool _bulkMode = false;

  String _selectedBlock = 'Bloco A';

  final _numberController = TextEditingController();

  final _floorsController = TextEditingController();
  final _apartmentsPerFloorController = TextEditingController();
  final _firstNumberController = TextEditingController(text: '101');

  @override
  void dispose() {
    _numberController.dispose();
    _floorsController.dispose();
    _apartmentsPerFloorController.dispose();
    _firstNumberController.dispose();
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

              _buildModeSelector(context),

              const SizedBox(height: 24),

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
              AppRoutes.condominiumApartments.replaceFirst(
                ':condominiumId',
                widget.condominiumId,
              ),
            );
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Apartamentos'),
        ),
        const SizedBox(height: 20),
        Text(
          'Novo apartamento',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Adicione um apartamento individualmente ou gere vários de uma vez.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.home_outlined),
              label: Text('Individual'),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.auto_awesome_outlined),
              label: Text('Gerar em lote'),
            ),
          ],
          selected: {_bulkMode},
          onSelectionChanged: (selection) {
            setState(() {
              _bulkMode = selection.first;
            });
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isSmall) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 20 : 24),
        child: Form(
          key: _formKey,
          child: _bulkMode
              ? _buildBulkForm(context, isSmall)
              : _buildIndividualForm(context, isSmall),
        ),
      ),
    );
  }

  Widget _buildIndividualForm(BuildContext context, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cadastro individual',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Cadastre um único apartamento.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        _buildBlockDropdown(),

        const SizedBox(height: 20),

        TextFormField(
          controller: _numberController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Número do apartamento',
            hintText: 'Ex.: 101',
            prefixIcon: Icon(Icons.home_work_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Informe o número do apartamento';
            }

            return null;
          },
        ),

        const SizedBox(height: 32),

        _buildActions(context),
      ],
    );
  }

  Widget _buildBulkForm(BuildContext context, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gerar apartamentos em lote',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Use esta opção para criar vários apartamentos automaticamente.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        _buildBlockDropdown(),

        const SizedBox(height: 20),

        if (isSmall)
          Column(
            children: [
              _buildNumberField(
                controller: _floorsController,
                label: 'Quantidade de andares',
                hint: 'Ex.: 10',
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                controller: _apartmentsPerFloorController,
                label: 'Apartamentos por andar',
                hint: 'Ex.: 4',
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: _floorsController,
                  label: 'Quantidade de andares',
                  hint: 'Ex.: 10',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  controller: _apartmentsPerFloorController,
                  label: 'Apartamentos por andar',
                  hint: 'Ex.: 4',
                ),
              ),
            ],
          ),

        const SizedBox(height: 20),

        TextFormField(
          controller: _firstNumberController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Primeiro apartamento',
            hintText: 'Ex.: 101',
            prefixIcon: Icon(Icons.looks_one_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Informe o primeiro apartamento';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Exemplo: 10 andares com 4 apartamentos por andar '
                    'irá gerar 40 apartamentos.',
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        _buildActions(context),
      ],
    );
  }

  Widget _buildBlockDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedBlock,
      decoration: const InputDecoration(
        labelText: 'Bloco',
        prefixIcon: Icon(Icons.domain_outlined),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Bloco A', child: Text('Bloco A')),
        DropdownMenuItem(value: 'Bloco B', child: Text('Bloco B')),
        DropdownMenuItem(value: 'Bloco C', child: Text('Bloco C')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedBlock = value;
        });
      },
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Informe este campo';
        }

        final number = int.tryParse(value);

        if (number == null || number <= 0) {
          return 'Informe um número válido';
        }

        return null;
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {
            context.go(
              AppRoutes.condominiumApartments.replaceFirst(
                ':condominiumId',
                widget.condominiumId,
              ),
            );
          },
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _createApartments,
          icon: const Icon(Icons.check),
          label: Text(_bulkMode ? 'Gerar apartamentos' : 'Criar apartamento'),
        ),
      ],
    );
  }

  void _createApartments() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_bulkMode) {
      final floors = int.parse(_floorsController.text);
      final apartmentsPerFloor = int.parse(_apartmentsPerFloorController.text);

      final total = floors * apartmentsPerFloor;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$total apartamentos gerados com sucesso.')),
      );
    } else {
      final number = _numberController.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apartamento $number criado com sucesso.')),
      );
    }

    context.go(
      AppRoutes.condominiumApartments.replaceFirst(
        ':condominiumId',
        widget.condominiumId,
      ),
    );
  }
}
