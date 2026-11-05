import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/features/auth/auth_controller.dart';

import '../routes/app_routes.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        if (isCompact) {
          return Scaffold(
            appBar: AppBar(title: const Text('MedeJá Admin')),
            drawer: Drawer(
              child: SafeArea(
                child: _buildSidebarContent(
                  context,
                  ref,
                  closeDrawerOnNavigate: true,
                ),
              ),
            ),
            body: child,
          );
        }

        return Scaffold(
          body: Row(
            children: [
              Container(
                width: 240,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: _buildSidebarContent(
                  context,
                  ref,
                  closeDrawerOnNavigate: false,
                ),
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    WidgetRef ref, {
    required bool closeDrawerOnNavigate,
  }) {
    void navigateTo(String route) {
      if (closeDrawerOnNavigate && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      context.go(route);
    }

    return Column(
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
          onTap: () => navigateTo(AppRoutes.dashboard),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('GESTÃO'),
        _SidebarItem(
          icon: Icons.business_outlined,
          label: 'Administradoras',
          route: AppRoutes.administrators,
          onTap: () => navigateTo(AppRoutes.administrators),
        ),
        _SidebarItem(
          icon: Icons.apartment_outlined,
          label: 'Condomínios',
          route: AppRoutes.condominiums,
          onTap: () => navigateTo(AppRoutes.condominiums),
        ),
        _SidebarItem(
          icon: Icons.people_outline,
          label: 'Contas e usuários',
          route: AppRoutes.accounts,
          onTap: () => navigateTo(AppRoutes.accounts),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('OPERAÇÃO'),
        _SidebarItem(
          icon: Icons.speed_outlined,
          label: 'Leituras',
          route: AppRoutes.readings,
          onTap: () => navigateTo(AppRoutes.readings),
        ),
        _SidebarItem(
          icon: Icons.description_outlined,
          label: 'Relatórios',
          route: AppRoutes.reports,
          onTap: () => navigateTo(AppRoutes.reports),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () => _confirmLogout(
              context,
              ref,
              closeDrawerFirst: closeDrawerOnNavigate,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref, {
    required bool closeDrawerFirst,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair do painel'),
          content: const Text(
            'Deseja realmente encerrar a sessão atual no MedeJá Admin?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (closeDrawerFirst && context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    await ref.read(authControllerProvider.notifier).logout();
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
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.onTap,
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
        onTap: onTap,
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
