/// auth_provider.dart — ChangeNotifier gérant l'état d'authentification global
///
/// Utilisé via [Provider] pour propager l'état de connexion dans tout l'arbre
/// de widgets Flutter sans prop-drilling.
///
/// Usage :
///   ```dart
///   // Lecture
///   final auth = context.watch<AuthProvider>();
///   if (auth.isAuthenticated) { ... }
///
///   // Action
///   await context.read<AuthProvider>().login(email, password);
///   ```

import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  // ── État ────────────────────────────────────────────────────────────────────

  /// true si un token valide est présent dans SharedPreferences
  bool _isAuthenticated = false;

  /// Utilisateur actuellement connecté (null si déconnecté)
  User? _currentUser;

  /// Token JWT courant (null si déconnecté)
  String? _token;

  /// true pendant un appel réseau (login / register / checkAuth)
  bool _isLoading = false;

  /// Message d'erreur de la dernière opération, ou null
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool   get isAuthenticated => _isAuthenticated;
  User?  get currentUser     => _currentUser;
  String? get token          => _token;
  bool   get isLoading       => _isLoading;
  String? get error          => _error;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Vérifie si une session existe déjà (appelé au démarrage de l'app).
  ///
  /// Charge le token et l'utilisateur depuis SharedPreferences.
  Future<void> checkAuth() async {
    _setLoading(true);
    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (loggedIn) {
        _token           = await AuthService.getToken();
        _currentUser     = await AuthService.getCurrentUser() ?? await AuthService.fetchMe();
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _currentUser     = null;
        _token           = null;
      }
    } catch (e) {
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  /// Met à jour le profil du locataire côté API puis recharge l'état local.
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    _setLoading(true);
    _error = null;
    try {
      final updatedUser = await AuthService.updateProfile(fields);
      if (updatedUser == null) {
        _error = 'Impossible de mettre à jour le profil.';
        notifyListeners();
        return false;
      }

      _currentUser = updatedUser;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  /// Connecte l'utilisateur et met à jour l'état global.
  ///
  /// Retourne true en cas de succès, false sinon.
  /// L'erreur est disponible dans [error].
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await AuthService.login(email, password);
      if (result['success'] == true) {
        _token           = result['token'] as String?;
        _currentUser     = User.fromJson(result['user'] as Map<String, dynamic>);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] as String? ?? 'Connexion échouée.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Inscrit un nouvel utilisateur et met à jour l'état global.
  ///
  /// [fields] doit contenir les champs requis par l'API register.
  /// Retourne true en cas de succès.
  Future<bool> register(Map<String, dynamic> fields) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await AuthService.register(fields);
      if (result['success'] == true) {
        _token           = result['token'] as String?;
        _currentUser     = User.fromJson(result['user'] as Map<String, dynamic>);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] as String? ?? 'Inscription échouée.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Déconnecte l'utilisateur et efface la session locale.
  Future<void> logout() async {
    _setLoading(true);
    try {
      await AuthService.logout();
    } finally {
      _isAuthenticated = false;
      _currentUser     = null;
      _token           = null;
      _setLoading(false);
    }
  }

  // ── Helpers privés ──────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
