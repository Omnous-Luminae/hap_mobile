/// main.dart — Point d'entrée de l'application HAP Mobile
///
/// Configure :
///   - Le thème sombre avec les couleurs HAP (#1a1a2e, #e94560)
///   - Le routeur go_router avec les routes nommées
///   - Le Provider AuthProvider pour l'état d'authentification global
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/bien_detail/bien_detail_screen.dart';
import 'models/bien.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  final authProvider = AuthProvider();
  await authProvider.checkAuth();

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: const HapApp(),
    ),
  );
}

// ── Routeur go_router ──────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/bien/:id',
      builder: (context, state) {
        final bien = state.extra as Bien?;
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return BienDetailScreen(id: id, initialBien: bien);
      },
    ),
  ],
);

// ── Application principale ─────────────────────────────────────────────────

class HapApp extends StatelessWidget {
  const HapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HAP Mobile',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFe94560),
          brightness: Brightness.dark,
          surface: const Color(0xFF1a1a2e),
        ),
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213e),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFe94560),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF16213e),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFe94560), width: 1.5),
          ),
        ),
      ),
    );
  }
}
