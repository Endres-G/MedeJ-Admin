import 'package:flutter/material.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final List<Account> _accounts = [
    Account(
      id: 'ACC-001',
      name: 'João da Silva',
      email: 'joao@email.com',
      status: AccountStatus.active,
      condominium: 'Residencial Jardim',
    ),
    Account(
      id: 'ACC-002',
      name: 'Maria Souza',
      email: 'maria@email.com',
      status: AccountStatus.active,
      condominium: 'Edifício Central',
    ),
    Account(id: 'ACC-003', name: '', email: '', status: AccountStatus.inactive),
    Account(
      id: 'ACC-004',
      name: 'Carlos Oliveira',
      email: 'carlos@email.com',
      status: AccountStatus.inactive,
      condominium: 'Residencial Aurora',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildSummary(),
            const SizedBox(height: 24),
            Expanded(child: _buildAccountsTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contas',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gerencie as contas disponíveis e vinculadas aos condomínios.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        );

        final button = FilledButton.icon(
          onPressed: _showCreateAccountDialog,
          icon: const Icon(Icons.add),
          label: const Text('Nova conta'),
        );

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), button],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            button,
          ],
        );
      },
    );
  }

  Widget _buildSummary() {
    final active = _accounts
        .where((account) => account.status == AccountStatus.active)
        .length;

    final inactive = _accounts
        .where((account) => account.status == AccountStatus.inactive)
        .length;

    final available = _accounts
        .where(
          (account) =>
              account.status == AccountStatus.inactive &&
              account.condominium == null,
        )
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;

        int columns;

        if (constraints.maxWidth >= 1100) {
          columns = 4;
        } else if (constraints.maxWidth >= 700) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Total de contas',
                value: '${_accounts.length}',
                icon: Icons.key_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Ativas',
                value: '$active',
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Inativas',
                value: '$inactive',
                icon: Icons.pause_circle_outline,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Disponíveis',
                value: '$available',
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountsTable() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columnSpacing: 32,
            columns: const [
              DataColumn(label: Text('Conta')),
              DataColumn(label: Text('Usuário')),
              DataColumn(label: Text('Condomínio')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Ações')),
            ],
            rows: _accounts.map((account) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      account.id,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    account.name.isEmpty
                        ? const Text('-')
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(account.name),
                              Text(
                                account.email,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                  ),
                  DataCell(Text(account.condominium ?? 'Disponível')),
                  DataCell(_StatusChip(status: account.status)),
                  DataCell(
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'toggle':
                            _toggleAccount(account);
                            break;
                          case 'view':
                            _showAccountDetails(account);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text('Visualizar'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            account.status == AccountStatus.active
                                ? 'Desativar'
                                : 'Ativar',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _toggleAccount(Account account) {
    setState(() {
      account.status = account.status == AccountStatus.active
          ? AccountStatus.inactive
          : AccountStatus.active;
    });
  }

  void _showAccountDetails(Account account) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Conta ${account.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuário: ${account.name.isEmpty ? '-' : account.name}'),
              const SizedBox(height: 8),
              Text('E-mail: ${account.email.isEmpty ? '-' : account.email}'),
              const SizedBox(height: 8),
              Text('Condomínio: ${account.condominium ?? 'Nenhum'}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Status: '),
                  _StatusChip(status: account.status),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateAccountDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova conta'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
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
                if (nameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  _accounts.add(
                    Account(
                      id: 'ACC-${(_accounts.length + 1).toString().padLeft(3, '0')}',
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      status: AccountStatus.inactive,
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('Criar conta'),
            ),
          ],
        );
      },
    );
  }
}

enum AccountStatus { active, inactive }

class Account {
  final String id;
  final String name;
  final String email;
  final String? condominium;
  AccountStatus status;

  Account({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.condominium,
  });
}

class _StatusChip extends StatelessWidget {
  final AccountStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == AccountStatus.active;

    return Chip(
      label: Text(isActive ? 'Ativa' : 'Inativa'),
      avatar: Icon(isActive ? Icons.check : Icons.pause, size: 16),
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
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 30),
              const SizedBox(width: 16),
              Column(
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
            ],
          ),
        ),
      ),
    );
  }
}
