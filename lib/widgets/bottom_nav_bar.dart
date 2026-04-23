/// bottom_nav_bar.dart — Barre de navigation inférieure HAP Mobile
///
/// 5 onglets :
///   0 → Accueil   (HomeScreen)
///   1 → Carte     (MapScreen)
///   2 → Favoris   (FavorisScreen)
///   3 → Réservations (ReservationsScreen)
///   4 → Profil    (ProfileScreen)
library;

import 'package:flutter/material.dart';

/// Barre de navigation inférieure avec le style HAP.
class HapBottomNavBar extends StatelessWidget {
  /// Index de l'onglet actuellement sélectionné.
  final int currentIndex;

  /// Appelé lorsque l'utilisateur sélectionne un onglet.
  final ValueChanged<int> onTap;

  static const Color _accent = Color(0xFFe94560);
  static const Color _bg     = Color(0xFF16213e);

  const HapBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: _bg,
      selectedItemColor: _accent,
      unselectedItemColor: Colors.white38,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Carte',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          activeIcon: Icon(Icons.favorite),
          label: 'Favoris',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month),
          label: 'Réservations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
