import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';

class AdminDetailsPage extends StatelessWidget {
  final String administratorId;

  const AdminDetailsPage({super.key, required this.administratorId});

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

              _buildCondominiums(context),
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
            Icons.business_outlined,
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
                'Administradora ABC',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'contato@abc.com',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Chip(
                label: const Text('Ativa'),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
              ),
            ],
          ),
        ),
      ],
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(context),
          const SizedBox(height: 20),
          header,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildBackButton(context), const SizedBox(height: 24), header],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.go(AppRoutes.administrators),
      icon: const Icon(Icons.arrow_back),
      label: const Text('Administradoras'),
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
                title: 'Condomínios',
                value: '8',
                icon: Icons.apartment_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: const _SummaryCard(
                title: 'Contas',
                value: '24',
                icon: Icons.people_outline,
              ),
            ),
            SizedBox(
              width: width,
              child: const _SummaryCard(
                title: 'Apartamentos',
                value: '1.240',
                icon: Icons.home_work_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCondominiums(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Condomínios',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                context.go(
                  AppRoutes.newCondominium.replaceFirst(
                    ':administratorId',
                    administratorId,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo condomínio'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _CondominiumTile(
                name: 'Residencial Jardim',
                details: '3 blocos • 120 apartamentos',
                status: 'Configuração completa',
                onOpen: () {
                  context.go(
                    AppRoutes.condominiumDetails.replaceFirst(
                      ':condominiumId',
                      'cond-001',
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _CondominiumTile(
                name: 'Edifício Central',
                details: '2 blocos • 80 apartamentos',
                status: 'Configuração incompleta',
                onOpen: () {
                  context.go(
                    AppRoutes.condominiumDetails.replaceFirst(
                      ':condominiumId',
                      'cond-002',
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _CondominiumTile(
                name: 'Residencial Aurora',
                details: '4 blocos • 160 apartamentos',
                status: 'Configuração completa',
                onOpen: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CondominiumTile extends StatelessWidget {
  final String name;
  final String details;
  final String status;
  final VoidCallback onOpen;

  const _CondominiumTile({
    required this.name,
    required this.details,
    required this.status,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = status == 'Configuração completa';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: CircleAvatar(
        child: Icon(
          Icons.apartment_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(details),
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            label: Text(status),
            backgroundColor: isComplete
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.tertiaryContainer,
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
    );
  }
}
