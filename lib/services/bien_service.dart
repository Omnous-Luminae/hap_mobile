/// bien_service.dart — Service d'accès aux données des biens
///
/// Encapsule tous les appels HTTP relatifs aux biens :
///   - [getBiens] : liste paginée et filtrée
///   - [toggleFavori] : basculer un favori
///   - [getFavoris] : liste des IDs favoris de l'utilisateur
///
/// Tous les appels HTTP sont délégués à [ApiService].
library;

import '../config/api_config.dart';
import '../models/bien.dart';
import '../models/filter_options.dart';
import 'api_service.dart';

/// Service pour les biens immobiliers HAP Mobile.
class BienService {
  /// Récupère une page de biens depuis l'API avec les filtres optionnels.
  ///
  /// Retourne une map avec :
  ///   - `data`        : `List<Bien>`
  ///   - `total`       : nombre total de biens correspondants
  ///   - `page`        : page courante
  ///   - `per_page`    : résultats par page
  ///   - `total_pages` : nombre total de pages
  static Future<Map<String, dynamic>> getBiens({
    FilterOptions? filters,
    int page = 1,
    int perPage = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (filters != null) {
      params.addAll(filters.toQueryParams());
    }

    final response = await ApiService.get(
      ApiConfig.biens,
      params: params,
    ) as Map<String, dynamic>;

    final rawData = (response['data'] as List<dynamic>?) ?? [];
    final biens = rawData
        .map((e) => Bien.fromJson(e as Map<String, dynamic>))
        .toList();

    return {
      'data':        biens,
      'total':       response['total'] as int? ?? 0,
      'page':        response['page'] as int? ?? page,
      'per_page':    response['per_page'] as int? ?? perPage,
      'total_pages': response['total_pages'] as int? ?? 1,
    };
  }

  /// Bascule le statut de favori pour le bien [bienId].
  ///
  /// Retourne true si le bien est maintenant en favori, false sinon.
  /// Le [token] est accepté pour la signature de l'API mais [ApiService]
  /// gère automatiquement l'envoi du token JWT via SharedPreferences.
  static Future<bool> toggleFavori(int bienId, String token) async {
    final response = await ApiService.post(
      '${ApiConfig.favoris}?action=toggle',
      {'id_biens': bienId},
    ) as Map<String, dynamic>;

    // L'API retourne { "success": true, "is_favorite": true/false }
    return response['is_favorite'] as bool? ?? false;
  }

  /// Récupère la liste des IDs de biens mis en favoris par l'utilisateur.
  ///
  /// Le [token] est accepté pour la signature de l'API mais [ApiService]
  /// gère automatiquement l'envoi du token JWT via SharedPreferences.
  /// Retourne une liste vide en cas d'erreur.
  static Future<List<int>> getFavoris(String token) async {
    try {
      final response = await ApiService.get(
        ApiConfig.favoris,
        params: {'action': 'list'},
      ) as Map<String, dynamic>;

      final rawList = (response['data'] as List<dynamic>?) ?? [];
      return rawList.map((e) => e as int).toList();
    } catch (_) {
      return [];
    }
  }

  /// Retourne des suggestions de biens pour l'autocomplétion.
  static Future<List<Map<String, dynamic>>> searchSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final response = await ApiService.get(
      ApiConfig.searchBiens,
      params: {'q': trimmed},
      includeAuth: false,
      clearSessionOn401: false,
    ) as Map<String, dynamic>;

    final raw = (response['data'] as List<dynamic>?) ?? const [];
    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
