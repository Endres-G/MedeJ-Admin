import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MedeJá Admin',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 32),

          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: AppRoutes.dashboard,
          ),

          const SizedBox(height: 20),

          _buildSectionTitle('GESTÃO'),

          _SidebarItem(
            icon: Icons.business_outlined,
            label: 'Administradoras',
            route: AppRoutes.administrators,
          ),

          _SidebarItem(
            icon: Icons.apartment_outlined,
            label: 'Condomínios',
            route: AppRoutes.condominiums,
          ),

          _SidebarItem(
            icon: Icons.people_outline,
            label: 'Contas e usuários',
            route: AppRoutes.accounts,
          ),

          const SizedBox(height: 20),

          _buildSectionTitle('OPERAÇÃO'),

          _SidebarItem(
            icon: Icons.speed_outlined,
            label: 'Leituras',
            route: AppRoutes.readings,
          ),

          _SidebarItem(
            icon: Icons.description_outlined,
            label: 'Relatórios',
            route: AppRoutes.reports,
          ),

          const Spacer(),

          _SidebarItem(icon: Icons.logout, label: 'Sair', route: '/'),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;

    final isSelected = _isRouteSelected(currentLocation, route);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        selected: isSelected,
        leading: Icon(icon),
        title: Text(label),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          context.go(route);
        },
      ),
    );
  }

  bool _isRouteSelected(String currentLocation, String route) {
    if (currentLocation == route) {
      return true;
    }

    return route != AppRoutes.dashboard &&
        currentLocation.startsWith('$route/');
  }
}
