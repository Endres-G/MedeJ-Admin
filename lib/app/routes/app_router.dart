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
  static NoTransitionPage<void> _noTransitionPage(
    GoRouterState state,
    Widget child,
  ) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

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
        pageBuilder: (context, state) {
          return _noTransitionPage(state, const LoginPage());
        },
      ),
      ShellRoute(
        pageBuilder: (context, state, child) {
          return _noTransitionPage(
            state,
            AppShell(currentPath: state.uri.path, child: child),
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) {
              return _noTransitionPage(state, const DashboardPage());
            },
          ),
          GoRoute(
            path: AppRoutes.administrators,
            pageBuilder: (context, state) {
              return _noTransitionPage(state, const AdministratorsPage());
            },
          ),
          GoRoute(
            path: AppRoutes.administratorDetails,
            pageBuilder: (context, state) {
              return _noTransitionPage(
                state,
                AdminDetailsPage(
                  administratorId: state.pathParameters['administratorId']!,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.newCondominium,
            pageBuilder: (context, state) {
              return _noTransitionPage(
                state,
                NewCondominiumPage(
                  administratorId: state.pathParameters['administratorId']!,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.condominiums,
            pageBuilder: (context, state) {
              return _noTransitionPage(state, const CondominiumsPage());
            },
          ),
          GoRoute(
            path: AppRoutes.condominiumDetails,
            pageBuilder: (context, state) {
              return _noTransitionPage(
                state,
                CondominiumDetailsPage(
                  condominiumId: state.pathParameters['condominiumId']!,
                  administratorId: state.uri.queryParameters['administratorId'],
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.condominiumBlocks,
            pageBuilder: (context, state) {
              return _noTransitionPage(
                state,
                BlocksPage(
                  condominiumId: state.pathParameters['condominiumId']!,
                  administratorId: state.uri.queryParameters['administratorId'],
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.newBlock,
            pageBuilder: (context, state) {
              return _noTransitionPage(
                state,
                NewBlockPage(
                  condominiumId: state.pathParameters['condominiumId']!,
                  administratorId: state.uri.queryParameters['administratorId'],
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.blockDetails,
            pageBuilder: (context, state) {
              return _noTransitionPage(
                state,
                BlockDetailsPage(
                  condominiumId: state.pathParameters['condominiumId']!,
                  blockId: state.pathParameters['blockId']!,
                  administratorId: state.uri.queryParameters['administratorId'],
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.condominiumApartments,
            pageBuilder: (context, state) {
              return _noTransitionPage(
                state,
                ApartmentsPage(
                  condominiumId: state.pathParameters['condominiumId']!,
                  administratorId: state.uri.queryParameters['administratorId'],
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.newApartment,
            pageBuilder: (context, state) {
              return _noTransitionPage(
                state,
                NewApartmentPage(
                  condominiumId: state.pathParameters['condominiumId']!,
                  administratorId: state.uri.queryParameters['administratorId'],
                  blockId: state.uri.queryParameters['blockId'],
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.condominiumUsers,
            pageBuilder: (context, state) {
              return _noTransitionPage(
                state,
                CondominiumUsersPage(
                  condominiumId: state.pathParameters['condominiumId']!,
                  administratorId: state.uri.queryParameters['administratorId'],
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.newCondominiumUser,
            pageBuilder: (context, state) {
              return _noTransitionPage(
                state,
                NewCondominiumUserPage(
                  condominiumId: state.pathParameters['condominiumId']!,
                  administratorId: state.uri.queryParameters['administratorId'],
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.accounts,
            pageBuilder: (context, state) {
              return _noTransitionPage(state, const AccountsPage());
            },
          ),
          GoRoute(
            path: AppRoutes.readings,
            pageBuilder: (context, state) {
              return _noTransitionPage(state, const ReadingsPage());
            },
          ),
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (context, state) {
              return _noTransitionPage(state, const ReportsPage());
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
