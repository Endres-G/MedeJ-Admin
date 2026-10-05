import 'package:flutter/material.dart';

import 'routes/app_router.dart';

class MedejaAdminApp extends StatelessWidget {
  const MedejaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MedeJá Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
