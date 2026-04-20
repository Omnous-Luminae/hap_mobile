/// auth_service.dart — Service d'authentification JWT pour HAP Mobile
///
/// Gère :
///   - La connexion (login) et l'inscription (register) via l'API PHP
///   - La persistance du token JWT et des données utilisateur dans SharedPreferences
///   - La récupération du profil courant (depuis le cache ou l'API)
///   - La déconnexion (logout)

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  // ── Clés SharedPreferences ─────────────────────────────────────────────────
  static const String _tokenKey = 'auth_token';
  static const String _userKey  = 'auth_user';

  // ── Authentification ────────────────────────────────────────────────────────

  /// Connecte un utilisateur avec son [email] et son [password].
  ///
  /// Retourne `{ success, token, user }` en cas de succès.
  /// Lance une [Exception] en cas d'échec réseau ou de credentials invalides.
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final data = await ApiService.post(ApiConfig.login, {
      'email': email,
      'password': password,
    }, includeAuth: false, clearSessionOn401: false) as Map<String, dynamic>;

    if (data['success'] == true) {
      await saveSession(
        data['token'] as String,
        data['user'] as Map<String, dynamic>,
      );
    }

    return data;
  }

  /// Inscrit un nouvel utilisateur.
  ///
  /// [fields] doit contenir : nom, prenom, email, password,
  /// et optionnellement : telephone, date_naissance, rue, id_commune.
  ///
  /// Retourne `{ success, token, user }` en cas de succès.
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> fields,
  ) async {
    final data = await ApiService.post(
      ApiConfig.register,
      fields,
      includeAuth: false,
      clearSessionOn401: false,
    ) as Map<String, dynamic>;

    if (data['success'] == true) {
      await saveSession(
        data['token'] as String,
        data['user'] as Map<String, dynamic>,
      );
    }

    return data;
  }

  /// Déconnecte l'utilisateur : appelle l'API logout et efface la session locale.
  static Future<void> logout() async {
    try {
      // Informe le serveur (blacklist du token)
      await ApiService.post(ApiConfig.logout, {});
    } catch (_) {
      // On efface quand même la session locale même si l'appel échoue
    } finally {
      await clearSession();
    }
  }

  // ── État de connexion ───────────────────────────────────────────────────────

  /// Retourne true si un token JWT est stocké localement.
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Données utilisateur ─────────────────────────────────────────────────────

  /// Retourne l'utilisateur courant depuis le cache local (SharedPreferences).
  ///
  /// Retourne null si aucune session n'est active.
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;

    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Récupère le profil complet depuis l'API `/auth_me.php`.
  ///
  /// Met à jour le cache local et retourne le [User] mis à jour.
  /// Retourne null si le token est invalide ou si l'appel échoue.
  static Future<User?> fetchMe() async {
    try {
      final data =
          await ApiService.get(ApiConfig.me) as Map<String, dynamic>;

      if (data['success'] == true) {
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        await _saveUser(user);
        return user;
      }
    } catch (_) {}
    return null;
  }

  /// Met à jour le profil connecté via l'API.
  ///
  /// Retourne le [User] mis à jour, ou null si l'opération échoue.
  static Future<User?> updateProfile(Map<String, dynamic> fields) async {
    final data = await ApiService.post(
      ApiConfig.updateProfile,
      fields,
    ) as Map<String, dynamic>;

    if (data['success'] == true) {
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      await _saveUser(user);
      return user;
    }

    throw Exception(data['message'] ?? 'Mise à jour impossible.');
  }

  // ── Session ─────────────────────────────────────────────────────────────────

  /// Retourne le token JWT stocké, ou null s'il est absent.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Sauvegarde le [token] et les données [user] dans SharedPreferences.
  static Future<void> saveSession(
    String token,
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Efface le token et les données utilisateur du stockage local.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
