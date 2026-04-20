import '../config/api_config.dart';
import 'api_service.dart';

class FavorisService {
  static Future<List<Map<String, dynamic>>> getFavoris() async {
    final response = await ApiService.get(ApiConfig.favoris) as Map<String, dynamic>;
    final raw = (response['data'] as List<dynamic>?) ?? const [];
    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<void> retirerFavori({required int idBiens}) async {
    final response = await ApiService.delete(
      ApiConfig.favoris,
      body: {'id_biens': idBiens},
    ) as Map<String, dynamic>;

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Erreur lors de la suppression.');
    }
  }
}