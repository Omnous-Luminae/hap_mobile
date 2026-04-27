/// api_config.dart — URLs des endpoints PHP de l'API HAP Mobile
///
/// Par défaut, l'API pointe vers un serveur PHP local lancé sur le port 8080.
/// Vous pouvez surcharger la base URL à l'exécution avec :
///   flutter run --dart-define=API_BASE_URL=http://HOST:PORT
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/foundation.dart' show TargetPlatform;

class ApiConfig {
  // ── URL de base ────────────────────────────────────────────────────────────
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Base URL calculée à l'exécution :
  /// - web local   -> localhost
  /// - Android emu -> 10.0.2.2
  /// - iOS sim/desktop -> localhost
  /// - surcharge   -> --dart-define=API_BASE_URL=...
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://localhost';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2';
    }
    return 'http://localhost';
  }

  /// Préfixe commun de l'API dans ce dépôt.
  static String get _projectPath => '$baseUrl/php_api';

  // ── Auth mobile ────────────────────────────────────────────────────────────
  static String get login => '$_projectPath/api/mobile/auth_login.php';
  static String get register => '$_projectPath/api/mobile/auth_register.php';
  static String get me => '$_projectPath/api/mobile/auth_me.php';
  static String get logout => '$_projectPath/api/mobile/auth_logout.php';

  // ── Ressources ─────────────────────────────────────────────────────────────
  static String get biens            => '$_projectPath/api/mobile/get_biens_mobile.php';
  static String get bienDetail       => '$_projectPath/api/mobile/get_bien_detail.php';
  static String get communes         => '$_projectPath/api/search_communes.php';
  static String get favoris          => '$_projectPath/api/mobile/favoris.php';
  static String get disponibilites   => '$_projectPath/api/mobile/get_disponibilites.php';
  static String get createReservation => '$_projectPath/api/mobile/create_reservation.php';
  static String get mesReservations  => '$_projectPath/api/mobile/get_mes_reservations.php';
  static String get cancelReservation => '$_projectPath/api/mobile/cancel_reservation.php';
  static String get updateProfile    => '$_projectPath/api/mobile/update_profile.php';
  static String get searchBiens      => '$_projectPath/api/mobile/search_biens.php';
  static String get pois             => '$_projectPath/api/mobile/get_pois.php';

  // ── API publique française (autocomplete adresses) ─────────────────────────
  /// Pas de clé API nécessaire — usage libre.
  static const String adresseGouv = 'https://api-adresse.data.gouv.fr/search/';

  // ── Helpers ─────────────────────────────────────────────────────────────────
  static String photoUrl(String? lienPhoto) {
    if (lienPhoto == null || lienPhoto.isEmpty) return '';

    // URL absolue localhost → extraire uniquement le path
    if (lienPhoto.startsWith('http://localhost') ||
        lienPhoto.startsWith('http://127.0.0.1')) {
      final uri = Uri.tryParse(lienPhoto);
      if (uri != null) {
        return '$baseUrl${uri.path}';
      }
    }

    // URL absolue externe → retourner telle quelle
    if (lienPhoto.startsWith('http://') || lienPhoto.startsWith('https://')) {
      return lienPhoto;
    }

    // Chemin relatif
    return '$baseUrl/$lienPhoto';
  }
}

