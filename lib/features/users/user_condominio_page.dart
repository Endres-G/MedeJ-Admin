import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';

class CondominiumUsersPage extends StatefulWidget {
  final String condominiumId;

  const CondominiumUsersPage({super.key, required this.condominiumId});

  @override
  State<CondominiumUsersPage> createState() => _CondominiumUsersPageState();
}

class _CondominiumUsersPageState extends State<CondominiumUsersPage> {
  String _search = '';
  String _statusFilter = 'Todos';

  final List<_CondominiumUser> _users = const [
    _CondominiumUser(
      name: 'João Silva',
      email: 'joao@email.com',
      status: 'Ativo',
    ),
    _CondominiumUser(
      name: 'Maria Souza',
      email: 'maria@email.com',
      status: 'Ativo',
    ),
    _CondominiumUser(
      name: 'Carlos Oliveira',
      email: 'carlos@email.com',
      status: 'Inativo',
    ),
    _CondominiumUser(
      name: 'Ana Santos',
      email: 'ana@email.com',
      status: 'Ativo',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      final normalizedSearch = _search.toLowerCase();

      final matchesSearch =
          user.name.toLowerCase().contains(normalizedSearch) ||
          user.email.toLowerCase().contains(normalizedSearch);

      final matchesStatus =
          _statusFilter == 'Todos' || user.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isSmall),

              const SizedBox(height: 32),

              _buildSummary(context),

              const SizedBox(height: 32),

              _buildFilters(context, isSmall),

              const SizedBox(height: 16),

              _buildUsers(context, filteredUsers),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () {
            context.go(
              AppRoutes.condominiumDetails.replaceFirst(
                ':condominiumId',
                widget.condominiumId,
              ),
            );
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Condomínio'),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contas e usuários',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Residencial Jardim',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            if (!isSmall)
              FilledButton.icon(
                onPressed: () {
                  context.go(
                    AppRoutes.newCondominiumUser.replaceFirst(
                      ':condominiumId',
                      widget.condominiumId,
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Nova conta'),
              ),
          ],
        ),
        if (isSmall) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                context.go(
                  AppRoutes.newCondominiumUser.replaceFirst(
                    ':condominiumId',
                    widget.condominiumId,
                  ),
                );
              },
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Nova conta'),
            ),
          ),
        ],
      ],
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

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: const _SummaryCard(
                title: 'Total',
                value: '8',
                icon: Icons.people_outline,
              ),
            ),
            SizedBox(
              width: width,
              child: const _SummaryCard(
                title: 'Ativas',
                value: '7',
                icon: Icons.person_outline,
              ),
            ),
            SizedBox(
              width: width,
              child: const _SummaryCard(
                title: 'Inativas',
                value: '1',
                icon: Icons.person_off_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context, bool isSmall) {
    final searchField = TextField(
      decoration: const InputDecoration(
        labelText: 'Buscar usuário',
        hintText: 'Nome ou e-mail',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
    );

    final statusField = DropdownButtonFormField<String>(
      initialValue: _statusFilter,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Todos', child: Text('Todos')),
        DropdownMenuItem(value: 'Ativo', child: Text('Ativos')),
        DropdownMenuItem(value: 'Inativo', child: Text('Inativos')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _statusFilter = value;
        });
      },
    );

    if (isSmall) {
      return Column(
        children: [searchField, const SizedBox(height: 16), statusField],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 16),
        SizedBox(width: 220, child: statusField),
      ],
    );
  }

  Widget _buildUsers(BuildContext context, List<_CondominiumUser> users) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: users.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Nenhum usuário encontrado.')),
            )
          : Column(
              children: List.generate(users.length, (index) {
                final user = users[index];

                return Column(
                  children: [
                    _UserTile(user: user, onOpen: () {}),
                    if (index < users.length - 1) const Divider(height: 1),
                  ],
                );
              }),
            ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final _CondominiumUser user;
  final VoidCallback onOpen;

  const _UserTile({required this.user, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final isActive = user.status == 'Ativo';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: CircleAvatar(child: Text(user.name.substring(0, 1))),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(user.email),
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            label: Text(user.status),
            backgroundColor: isActive
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.errorContainer,
          ),
          FilledButton.tonal(onPressed: onOpen, child: const Text('Abrir')),
        ],
      ),
    );
  }
}

class _CondominiumUser {
  final String name;
  final String email;
  final String status;

  const _CondominiumUser({
    required this.name,
    required this.email,
    required this.status,
  });
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
