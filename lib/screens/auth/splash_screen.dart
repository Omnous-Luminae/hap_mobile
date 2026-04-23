/// splash_screen.dart — Écran de démarrage avec vérification de session JWT
///
/// Affiché au lancement de l'app, il :
///   1. Affiche le logo HAP pendant 1,5 secondes
///   2. Vérifie si un token JWT existe dans SharedPreferences
///   3. Redirige vers HomeScreen (connecté) ou LoginScreen (non connecté)
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation de fondu pour le logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    _checkSession();
  }

  /// Vérifie la session puis navigue vers l'écran approprié.
  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final isLoggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / icône de l'app
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFe94560),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.house_rounded,
                  color: Colors.white,
                  size: 72,
                ),
              ),
              const SizedBox(height: 24),
              // Titre de l'app
              const Text(
                'HAP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'House After Party',
                style: TextStyle(
                  color: Color(0xFFe94560),
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              // Indicateur de chargement discret
              const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFFe94560)),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
