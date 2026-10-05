import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';

class ApartmentsPage extends StatefulWidget {
  final String condominiumId;

  const ApartmentsPage({super.key, required this.condominiumId});

  @override
  State<ApartmentsPage> createState() => _ApartmentsPageState();
}

class _ApartmentsPageState extends State<ApartmentsPage> {
  String _selectedBlock = 'Todos';
  String _search = '';

  final List<_Apartment> _apartments = const [
    _Apartment(number: '101', block: 'Bloco A', status: 'Lido'),
    _Apartment(number: '102', block: 'Bloco A', status: 'Lido'),
    _Apartment(number: '103', block: 'Bloco A', status: 'Pendente'),
    _Apartment(number: '104', block: 'Bloco A', status: 'Lido'),
    _Apartment(number: '201', block: 'Bloco B', status: 'Lido'),
    _Apartment(number: '202', block: 'Bloco B', status: 'Pendente'),
    _Apartment(number: '203', block: 'Bloco B', status: 'Lido'),
    _Apartment(number: '301', block: 'Bloco C', status: 'Pendente'),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredApartments = _apartments.where((apartment) {
      final matchesBlock =
          _selectedBlock == 'Todos' || apartment.block == _selectedBlock;

      final matchesSearch = apartment.number.toLowerCase().contains(
        _search.toLowerCase(),
      );

      return matchesBlock && matchesSearch;
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

              _buildApartments(context, filteredApartments),
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
                    'Apartamentos',
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
                    AppRoutes.newApartment.replaceFirst(
                      ':condominiumId',
                      widget.condominiumId,
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Novo apartamento'),
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
                    widget.condominiumId,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo apartamento'),
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
                title: 'Apartamentos',
                value: '120',
                icon: Icons.home_work_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: const _SummaryCard(
                title: 'Com leitura',
                value: '87',
                icon: Icons.speed_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: const _SummaryCard(
                title: 'Pendentes',
                value: '33',
                icon: Icons.pending_actions_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context, bool isSmall) {
    final filters = [
      Expanded(
        child: TextField(
          decoration: const InputDecoration(
            labelText: 'Buscar apartamento',
            hintText: 'Ex.: 101',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _search = value;
            });
          },
        ),
      ),
      const SizedBox(width: 16),
      SizedBox(
        width: isSmall ? double.infinity : 220,
        child: DropdownButtonFormField<String>(
          initialValue: _selectedBlock,
          decoration: const InputDecoration(
            labelText: 'Bloco',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Todos', child: Text('Todos os blocos')),
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
        ),
      ),
    ];

    if (isSmall) {
      return Column(
        children: [filters[0], const SizedBox(height: 16), filters[2]],
      );
    }

    return Row(children: filters);
  }

  Widget _buildApartments(BuildContext context, List<_Apartment> apartments) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (apartments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Nenhum apartamento encontrado.')),
            )
          else
            ...List.generate(apartments.length, (index) {
              final apartment = apartments[index];

              return Column(
                children: [
                  _ApartmentTile(apartment: apartment, onOpen: () {}),
                  if (index < apartments.length - 1) const Divider(height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _ApartmentTile extends StatelessWidget {
  final _Apartment apartment;
  final VoidCallback onOpen;

  const _ApartmentTile({required this.apartment, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final isRead = apartment.status == 'Lido';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: CircleAvatar(
        child: Icon(
          Icons.home_work_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        'Apartamento ${apartment.number}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(apartment.block),
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            label: Text(apartment.status),
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

class _Apartment {
  final String number;
  final String block;
  final String status;

  const _Apartment({
    required this.number,
    required this.block,
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
