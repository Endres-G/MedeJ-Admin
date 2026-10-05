import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';

class CondominiumDetailsPage extends StatelessWidget {
  final String condominiumId;

  const CondominiumDetailsPage({super.key, required this.condominiumId});

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

              const SizedBox(height: 32),

              _buildSummary(context),

              const SizedBox(height: 32),

              _buildStructure(context),

              const SizedBox(height: 32),

              _buildUsers(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmall) {
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          child: Icon(
            Icons.apartment_outlined,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Residencial Jardim',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Rua das Flores, 100',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Chip(
                label: const Text('Ativo'),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
              ),
            ],
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go(AppRoutes.administrators),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Administradoras'),
        ),
        const SizedBox(height: 24),
        header,
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
                title: 'Blocos',
                value: '3',
                icon: Icons.domain_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: const _SummaryCard(
                title: 'Apartamentos',
                value: '120',
                icon: Icons.home_work_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: const _SummaryCard(
                title: 'Contas',
                value: '8',
                icon: Icons.people_outline,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStructure(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Estrutura',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                context.go(
                  AppRoutes.condominiumBlocks.replaceFirst(
                    ':condominiumId',
                    condominiumId,
                  ),
                );
              },
              icon: const Icon(Icons.domain_add_outlined),
              label: const Text('Gerenciar blocos'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _StructureTile(
                icon: Icons.domain_outlined,
                title: 'Blocos',
                subtitle: '3 blocos cadastrados',
                onOpen: () {
                  context.go(
                    AppRoutes.condominiumBlocks.replaceFirst(
                      ':condominiumId',
                      condominiumId,
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _StructureTile(
                icon: Icons.home_work_outlined,
                title: 'Apartamentos',
                subtitle: '120 apartamentos cadastrados',
                onOpen: () {
                  context.go(
                    AppRoutes.condominiumApartments.replaceFirst(
                      ':condominiumId',
                      condominiumId,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsers(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Contas e usuários',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                context.go(
                  AppRoutes.condominiumUsers.replaceFirst(
                    ':condominiumId',
                    condominiumId,
                  ),
                );
              },
              icon: const Icon(Icons.people_outline),
              label: const Text('Gerenciar contas'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _UserTile(
                name: 'João Silva',
                email: 'joao@email.com',
                active: true,
              ),
              const Divider(height: 1),
              _UserTile(
                name: 'Maria Souza',
                email: 'maria@email.com',
                active: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StructureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onOpen;

  const _StructureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: CircleAvatar(
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle),
      ),
      trailing: FilledButton.tonal(
        onPressed: onOpen,
        child: const Text('Abrir'),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String name;
  final String email;
  final bool active;

  const _UserTile({
    required this.name,
    required this.email,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(child: Text(name.substring(0, 1))),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(email),
      trailing: Chip(
        label: Text(active ? 'Ativo' : 'Inativo'),
        backgroundColor: active
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.errorContainer,
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
