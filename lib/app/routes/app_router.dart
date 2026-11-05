import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/admin/admin_details_page.dart';
import 'package:mede_ja_admin/features/admin/admin_page.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamento_page.dart';
import 'package:mede_ja_admin/features/apartamentos/new_apartamento_page.dart';
import 'package:mede_ja_admin/features/auth/login_page.dart';
import 'package:mede_ja_admin/features/blocos/bloco_detail_page.dart';
import 'package:mede_ja_admin/features/blocos/bloco_page.dart';
import 'package:mede_ja_admin/features/blocos/new_bloco_page.dart';
import 'package:mede_ja_admin/features/condominos/condominio_detail_page.dart';
import 'package:mede_ja_admin/features/condominos/condominio_page.dart';
import 'package:mede_ja_admin/features/condominos/novo_condominio_page.dart';
import 'package:mede_ja_admin/features/contas/contas_page.dart';
import 'package:mede_ja_admin/features/dashboard/dashboard_page.dart';
import 'package:mede_ja_admin/features/leituras/leitura_page.dart';
import 'package:mede_ja_admin/features/report/report_page.dart';
import 'package:mede_ja_admin/features/users/new_condominio_user_page.dart';
import 'package:mede_ja_admin/features/users/user_condominio_page.dart';

import '../widgets/app_shell.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;
      final isLoginPage = location == AppRoutes.login;

      if (!isLoggedIn) {
        if (!isLoginPage) {
          return AppRoutes.login;
        }
        return null;
      }

      if (isLoginPage || location == '/') {
        return AppRoutes.dashboard;
      }

      return null;
    },
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.compass_calibration_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Página não encontrada',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A rota "${state.uri.path}" não existe no painel administrativo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Voltar ao Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          return const LoginPage();
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) {
              return const DashboardPage();
            },
          ),
          GoRoute(
            path: AppRoutes.administrators,
            builder: (context, state) {
              return const AdministratorsPage();
            },
          ),
          GoRoute(
            path: AppRoutes.administratorDetails,
            builder: (context, state) {
              return AdminDetailsPage(
                administratorId: state.pathParameters['administratorId']!,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.newCondominium,
            builder: (context, state) {
              return NewCondominiumPage(
                administratorId: state.pathParameters['administratorId']!,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.condominiums,
            builder: (context, state) {
              return const CondominiumsPage();
            },
          ),
          GoRoute(
            path: AppRoutes.condominiumDetails,
            builder: (context, state) {
              return CondominiumDetailsPage(
                condominiumId: state.pathParameters['condominiumId']!,
                administratorId: state.uri.queryParameters['administratorId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.condominiumBlocks,
            builder: (context, state) {
              return BlocksPage(
                condominiumId: state.pathParameters['condominiumId']!,
                administratorId: state.uri.queryParameters['administratorId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.newBlock,
            builder: (context, state) {
              return NewBlockPage(
                condominiumId: state.pathParameters['condominiumId']!,
                administratorId: state.uri.queryParameters['administratorId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.blockDetails,
            builder: (context, state) {
              return BlockDetailsPage(
                condominiumId: state.pathParameters['condominiumId']!,
                blockId: state.pathParameters['blockId']!,
                administratorId: state.uri.queryParameters['administratorId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.condominiumApartments,
            builder: (context, state) {
              return ApartmentsPage(
                condominiumId: state.pathParameters['condominiumId']!,
                administratorId: state.uri.queryParameters['administratorId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.newApartment,
            builder: (context, state) {
              return NewApartmentPage(
                condominiumId: state.pathParameters['condominiumId']!,
                administratorId: state.uri.queryParameters['administratorId'],
                blockId: state.uri.queryParameters['blockId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.condominiumUsers,
            builder: (context, state) {
              return CondominiumUsersPage(
                condominiumId: state.pathParameters['condominiumId']!,
                administratorId: state.uri.queryParameters['administratorId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.newCondominiumUser,
            builder: (context, state) {
              return NewCondominiumUserPage(
                condominiumId: state.pathParameters['condominiumId']!,
                administratorId: state.uri.queryParameters['administratorId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.accounts,
            builder: (context, state) {
              return const AccountsPage();
            },
          ),
          GoRoute(
            path: AppRoutes.readings,
            builder: (context, state) {
              return const ReadingsPage();
            },
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) {
              return const ReportsPage();
            },
          ),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
