import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdministratorsPage extends StatefulWidget {
  const AdministratorsPage({super.key});

  @override
  State<AdministratorsPage> createState() => _AdministratorsPageState();
}

class _AdministratorsPageState extends State<AdministratorsPage> {
  final List<Administrator> _administrators = [
    Administrator(
      id: 'ADM-001',
      name: 'Administradora ABC',
      email: 'contato@abc.com',
      condominiums: 8,
      accounts: 24,
      active: true,
    ),
    Administrator(
      id: 'ADM-002',
      name: 'Administradora XYZ',
      email: 'contato@xyz.com',
      condominiums: 3,
      accounts: 10,
      active: true,
    ),
    Administrator(
      id: 'ADM-003',
      name: 'Administradora Central',
      email: 'contato@central.com',
      condominiums: 5,
      accounts: 18,
      active: false,
    ),
  ];

  String _search = '';

  List<Administrator> get _filteredAdministrators {
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

  void _openAdministrator(Administrator administrator) {
    context.go('/administrators/${administrator.id}');
  }

  void _toggleAdministrator(Administrator administrator) {
    setState(() {
      administrator.active = !administrator.active;
    });
  }

  void _showCreateAdministratorDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova administradora'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Ex.: Administradora ABC',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    hintText: 'contato@empresa.com',
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
              onPressed: () {
                final name = nameController.text.trim();
                final email = emailController.text.trim();

                if (name.isEmpty || email.isEmpty) {
                  return;
                }

                setState(() {
                  _administrators.add(
                    Administrator(
                      id: 'ADM-${(_administrators.length + 1).toString().padLeft(3, '0')}',
                      name: name,
                      email: email,
                      condominiums: 0,
                      accounts: 0,
                      active: true,
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }
}

class Administrator {
  final String id;
  final String name;
  final String email;
  final int condominiums;
  final int accounts;
  bool active;

  Administrator({
    required this.id,
    required this.name,
    required this.email,
    required this.condominiums,
    required this.accounts,
    required this.active,
  });
}

class _AdministratorTile extends StatelessWidget {
  final Administrator administrator;
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
        child: Text(
          '${administrator.email} • '
          '${administrator.condominiums} condomínios • '
          '${administrator.accounts} contas',
        ),
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
