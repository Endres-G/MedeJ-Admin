import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';

class BlockDetailsPage extends StatelessWidget {
  final String condominiumId;
  final String blockId;

  const BlockDetailsPage({
    super.key,
    required this.condominiumId,
    required this.blockId,
  });

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
              _buildSummary(context),
              const SizedBox(height: 32),
              _buildApartments(context, isSmall),
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
                condominiumId,
              ),
            );
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Blocos'),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              child: Icon(
                Icons.domain_outlined,
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
                    'Bloco A',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Residencial Jardim',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
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
                title: 'Apartamentos',
                value: '40',
                icon: Icons.home_work_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: const _SummaryCard(
                title: 'Com leitura',
                value: '32',
                icon: Icons.speed_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: const _SummaryCard(
                title: 'Pendentes',
                value: '8',
                icon: Icons.pending_actions_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildApartments(BuildContext context, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Apartamentos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (!isSmall)
              FilledButton.icon(
                onPressed: () {
                  context.go(
                    AppRoutes.newApartment.replaceFirst(
                      ':condominiumId',
                      condominiumId,
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Adicionar apartamento'),
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
                  AppRoutes.newApartment.replaceFirst(
                    ':condominiumId',
                    condominiumId,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar apartamento'),
            ),
          ),
        ],

        const SizedBox(height: 16),

        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _ApartmentTile(number: '101', status: 'Lido', onOpen: () {}),
              const Divider(height: 1),
              _ApartmentTile(number: '102', status: 'Lido', onOpen: () {}),
              const Divider(height: 1),
              _ApartmentTile(number: '103', status: 'Pendente', onOpen: () {}),
              const Divider(height: 1),
              _ApartmentTile(number: '104', status: 'Lido', onOpen: () {}),
              const Divider(height: 1),
              _ApartmentTile(number: '105', status: 'Pendente', onOpen: () {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApartmentTile extends StatelessWidget {
  final String number;
  final String status;
  final VoidCallback onOpen;

  const _ApartmentTile({
    required this.number,
    required this.status,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = status == 'Lido';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: CircleAvatar(
        child: Icon(
          Icons.home_work_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        'Apartamento $number',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('Bloco A'),
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            label: Text(status),
            backgroundColor: isRead
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
