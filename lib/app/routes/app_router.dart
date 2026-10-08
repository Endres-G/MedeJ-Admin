import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:mede_ja_admin/app/routes/app_routes.dart';
import 'package:mede_ja_admin/features/auth/login_page.dart';
import 'package:mede_ja_admin/features/admin/admin_details_page.dart';
import 'package:mede_ja_admin/features/admin/admin_page.dart';
import 'package:mede_ja_admin/features/apartamentos/apartamento_page.dart';
import 'package:mede_ja_admin/features/apartamentos/new_apartamento_page.dart';
import 'package:mede_ja_admin/features/blocos/bloco_detail_page.dart';
import 'package:mede_ja_admin/features/blocos/bloco_page.dart';
import 'package:mede_ja_admin/features/blocos/new_bloco_page.dart';
import 'package:mede_ja_admin/features/condominos/condominio_detail_page.dart';
import 'package:mede_ja_admin/features/condominos/novo_condominio_page.dart';
import 'package:mede_ja_admin/features/dashboard/dashboard_page.dart';
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
      final isLoginPage = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn) {
        if (!isLoginPage) {
          return AppRoutes.login;
        }

        return null;
      }

      if (isLoginPage) {
        return AppRoutes.dashboard;
      }

      return null;
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
            path: AppRoutes.condominiumDetails,
            builder: (context, state) {
              return CondominiumDetailsPage(
                condominiumId: state.pathParameters['condominiumId']!,
              );
            },
          ),

          GoRoute(
            path: AppRoutes.condominiumBlocks,
            builder: (context, state) {
              return BlocksPage(
                condominiumId: state.pathParameters['condominiumId']!,
              );
            },
          ),

          GoRoute(
            path: AppRoutes.newBlock,
            builder: (context, state) {
              return NewBlockPage(
                condominiumId: state.pathParameters['condominiumId']!,
              );
            },
          ),

          GoRoute(
            path: AppRoutes.blockDetails,
            builder: (context, state) {
              return BlockDetailsPage(
                condominiumId: state.pathParameters['condominiumId']!,
                blockId: state.pathParameters['blockId']!,
              );
            },
          ),

          GoRoute(
            path: AppRoutes.condominiumApartments,
            builder: (context, state) {
              return ApartmentsPage(
                condominiumId: state.pathParameters['condominiumId']!,
              );
            },
          ),

          GoRoute(
            path: AppRoutes.newApartment,
            builder: (context, state) {
              return NewApartmentPage(
                condominiumId: state.pathParameters['condominiumId']!,
              );
            },
          ),

          GoRoute(
            path: AppRoutes.condominiumUsers,
            builder: (context, state) {
              return CondominiumUsersPage(
                condominiumId: state.pathParameters['condominiumId']!,
              );
            },
          ),

          GoRoute(
            path: AppRoutes.newCondominiumUser,
            builder: (context, state) {
              return NewCondominiumUserPage(
                condominiumId: state.pathParameters['condominiumId']!,
              );
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
