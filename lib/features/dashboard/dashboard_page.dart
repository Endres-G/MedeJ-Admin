import 'package:flutter/material.dart';
import 'package:mede_ja_admin/app/widgets/dashboard_card_widget.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmall ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Visão geral do MedeJá',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                const SizedBox(height: 32),

                _buildSummaryCards(context),

                const SizedBox(height: 40),

                Text(
                  'Condomínios',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                _buildCondominiums(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1100) {
          columns = 4;
        } else if (constraints.maxWidth >= 700) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 16.0;

        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: const DashboardCard(
                title: 'Administradoras',
                value: '12',
                icon: Icons.business_outlined,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: const DashboardCard(
                title: 'Condomínios',
                value: '28',
                icon: Icons.apartment_outlined,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: const DashboardCard(
                title: 'Contas',
                value: '120 / 150',
                icon: Icons.people_outline,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: const DashboardCard(
                title: 'Leituras',
                value: '87',
                icon: Icons.speed_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCondominiums(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildCondominiumItem(
            context,
            name: 'Residencial Jardim',
            date: '05/10/2026',
          ),

          const Divider(height: 1),

          _buildCondominiumItem(
            context,
            name: 'Edifício Central',
            date: '03/10/2026',
          ),
        ],
      ),
    );
  }

  Widget _buildCondominiumItem(
    BuildContext context, {
    required String name,
    required String date,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(name),
      subtitle: Text('Última leitura: $date'),
      trailing: Chip(
        label: const Text('Concluída'),
        backgroundColor: colorScheme.secondaryContainer,
      ),
    );
  }
}
