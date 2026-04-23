/// reservation_service.dart — Service d'accès aux données des réservations et détails des biens
library;

import '../config/api_config.dart';
import '../models/bien_detail.dart';
import '../models/reservation.dart';
import 'api_service.dart';

class ReservationService {
  /// Récupère le détail complet d'un bien (photos, avis, tarifs).
  static Future<BienDetail> getBienDetail(int idBiens) async {
    final response = await ApiService.get(
      ApiConfig.bienDetail,
      params: {'id': idBiens.toString()},
    ) as Map<String, dynamic>;

    return BienDetail.fromJson(response['bien'] as Map<String, dynamic>);
  }

  /// Récupère les plages de dates réservées pour un bien.
  /// Chaque map contient : `debut` (String) et `fin` (String) au format 'YYYY-MM-DD'.
  static Future<List<Map<String, String>>> getDisponibilites(int idBiens) async {
    final response = await ApiService.get(
      ApiConfig.disponibilites,
      params: {'id_biens': idBiens.toString()},
    ) as Map<String, dynamic>;

    final raw = (response['reserved_ranges'] as List<dynamic>?) ?? [];
    return raw
        .map((e) => {
              'debut': (e as Map<String, dynamic>)['debut'] as String,
              'fin':   e['fin']   as String,
            })
        .toList();
  }

  /// Crée une réservation pour l'utilisateur connecté.
  ///
  /// Retourne la réponse API :
  ///   `{ success, id_reservation, total_cost, tarif_semaine, nb_nuits }`
  static Future<Map<String, dynamic>> createReservation({
    required int idBiens,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return await ApiService.post(
      ApiConfig.createReservation,
      {
        'id_biens':   idBiens,
        'date_debut': fmt(dateDebut),
        'date_fin':   fmt(dateFin),
      },
    ) as Map<String, dynamic>;
  }

  /// Annule une réservation "à venir".
  static Future<void> cancelReservation({required int idReservation}) async {
    final response = await ApiService.post(
      ApiConfig.cancelReservation,
      {'id_reservation': idReservation},
    ) as Map<String, dynamic>;

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Annulation impossible.');
    }
  }


  /// Récupère toutes les réservations de l'utilisateur connecté.
  static Future<List<Reservation>> getMesReservations() async {
    final response = await ApiService.get(
      ApiConfig.mesReservations,
    ) as Map<String, dynamic>;

    final raw = (response['data'] as List<dynamic>?) ?? [];
    return raw
        .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}


