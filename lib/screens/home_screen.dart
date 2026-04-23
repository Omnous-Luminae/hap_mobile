/// home_screen.dart — Écran principal HAP Mobile (shell avec navigation)
///
/// Conteneur principal qui gère la navigation par onglets via [HapBottomNavBar].
/// Utilise un [IndexedStack] pour conserver l'état de chaque onglet.
library;

import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import 'favoris/favoris_screen.dart';
import 'home/home_screen.dart' as home;
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';
import 'reservations/reservations_screen.dart';

/// Shell principal avec barre de navigation inférieure à 5 onglets.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    home.HomeScreen(),
    MapScreen(),
    FavorisScreen(),
    ReservationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: HapBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
