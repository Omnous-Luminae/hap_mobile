/// api_service.dart — Client HTTP générique avec gestion automatique du JWT
///
/// Toutes les requêtes GET et POST incluent automatiquement le header
/// `Authorization: Bearer <token>` si un token est stocké localement.
/// Un code 401 déclenche une déconnexion automatique.
library;

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const Duration _requestTimeout = Duration(seconds: 20);

  // ── Token ──────────────────────────────────────────────────────────────────

  /// Retourne le JWT stocké dans [SharedPreferences], ou null s'il est absent.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ── Méthodes HTTP ──────────────────────────────────────────────────────────

  /// Effectue une requête GET vers [url].
  ///
  /// [params] : paramètres de query string optionnels.
  /// Ajoute automatiquement le header Authorization si un token existe.
  /// Lance une [Exception] en cas d'erreur HTTP.
  static Future<dynamic> get(
    String url, {
    Map<String, String>? params,
    bool includeAuth = true,
    bool clearSessionOn401 = true,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: params);
      final headers = await _buildHeaders(includeAuth: includeAuth);

      final response = await http.get(uri, headers: headers).timeout(_requestTimeout);
      return _handleResponse(response, clearSessionOn401: clearSessionOn401);
    } on TimeoutException {
      throw Exception('La requête a expiré. Vérifiez votre connexion.');
    } on http.ClientException {
      throw Exception('Connexion réseau indisponible.');
    }
  }

  /// Effectue une requête POST vers [url] avec [body] encodé en JSON.
  ///
  /// Ajoute automatiquement le header Authorization si un token existe.
  /// Lance une [Exception] en cas d'erreur HTTP.
  static Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    bool includeAuth = true,
    bool clearSessionOn401 = true,
  }
  ) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _buildHeaders(includeAuth: includeAuth);

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
      return _handleResponse(response, clearSessionOn401: clearSessionOn401);
    } on TimeoutException {
      throw Exception('La requête a expiré. Vérifiez votre connexion.');
    } on http.ClientException {
      throw Exception('Connexion réseau indisponible.');
    }
  }

  /// Effectue une requête DELETE vers [url] avec un corps JSON optionnel.
  static Future<dynamic> delete(
    String url, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    bool clearSessionOn401 = true,
  }) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _buildHeaders(includeAuth: includeAuth);

      final request = http.Request('DELETE', uri)..headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamed = await request.send().timeout(_requestTimeout);
      final response = await http.Response.fromStream(streamed).timeout(_requestTimeout);
      return _handleResponse(response, clearSessionOn401: clearSessionOn401);
    } on TimeoutException {
      throw Exception('La requête a expiré. Vérifiez votre connexion.');
    } on http.ClientException {
      throw Exception('Connexion réseau indisponible.');
    }
  }

  // ── Helpers privés ─────────────────────────────────────────────────────────

  /// Construit les headers communs (Content-Type + Authorization).
  static Future<Map<String, String>> _buildHeaders({
    bool includeAuth = true,
  }) async {
    final token = includeAuth ? await getToken() : null;
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Interprète la réponse HTTP et retourne le corps décodé.
  ///
  /// - 200 / 201 → retourne le JSON décodé
  /// - 401       → efface la session locale et lance une [UnauthorizedException]
  /// - autre     → lance une [Exception] avec le code et le message d'erreur
  static dynamic _handleResponse(
    http.Response response, {
    bool clearSessionOn401 = true,
  }) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      if (clearSessionOn401) {
        // Token invalide ou expiré : on efface la session locale
        _clearLocalSession();
      }

      String message = 'Non autorisé';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['message'] as String? ?? message;
      } catch (_) {}

      throw UnauthorizedException(message);
    }

    // Tente de lire le message d'erreur renvoyé par l'API
    String message = 'Erreur HTTP ${response.statusCode}';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] as String? ?? message;
    } catch (_) {}

    throw Exception(message);
  }

  /// Efface le token et les données utilisateur dans [SharedPreferences].
  static Future<void> _clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }
}

/// Exception levée lorsque l'API retourne un code 401.
class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}
