import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';

class BlocksPage extends StatelessWidget {
  final String condominiumId;

  const BlocksPage({super.key, required this.condominiumId});

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

              _buildBlocks(context),
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
                condominiumId,
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
                    'Blocos',
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
                onPressed: _openNewBlock,
                icon: const Icon(Icons.add),
                label: const Text('Novo bloco'),
              ),
          ],
        ),
        if (isSmall) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openNewBlock,
              icon: const Icon(Icons.add),
              label: const Text('Novo bloco'),
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
                title: 'Média por bloco',
                value: '40',
                icon: Icons.analytics_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlocks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blocos cadastrados',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _BlockTile(
                name: 'Bloco A',
                apartments: 40,
                onOpen: () => _openBlock('block-001'),
              ),
              const Divider(height: 1),
              _BlockTile(
                name: 'Bloco B',
                apartments: 40,
                onOpen: () => _openBlock('block-002'),
              ),
              const Divider(height: 1),
              _BlockTile(
                name: 'Bloco C',
                apartments: 40,
                onOpen: () => _openBlock('block-003'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openNewBlock() {
    final route = AppRoutes.newBlock.replaceFirst(
      ':condominiumId',
      condominiumId,
    );

    // O context não está disponível aqui porque o método
    // é chamado pelo build. Vamos usar uma versão com contexto abaixo.
  }

  void _openBlock(String blockId) {
    // Será conectado na próxima etapa.
  }
}

class _BlockTile extends StatelessWidget {
  final String name;
  final int apartments;
  final VoidCallback onOpen;

  const _BlockTile({
    required this.name,
    required this.apartments,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: CircleAvatar(
        child: Icon(
          Icons.domain_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text('$apartments apartamentos'),
      ),
      trailing: FilledButton.tonal(
        onPressed: onOpen,
        child: const Text('Abrir'),
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
