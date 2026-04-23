/// reservation.dart — Modèle d'une réservation utilisateur
library;

/// Informations condensées du bien dans une réservation.
class ReservationBien {
  final int idBiens;
  final String nomBiens;
  final String? nomCommune;
  final String? photo;

  const ReservationBien({
    required this.idBiens,
    required this.nomBiens,
    this.nomCommune,
    this.photo,
  });

  factory ReservationBien.fromJson(Map<String, dynamic> json) => ReservationBien(
        idBiens:    json['id_biens']    as int,
        nomBiens:   json['nom_biens']   as String? ?? '',
        nomCommune: json['nom_commune'] as String?,
        photo:      json['photo']       as String?,
      );
}

/// Statut d'une réservation.
enum StatutReservation { aVenir, enCours, termine }

/// Réservation d'un locataire.
class Reservation {
  final int idReservation;
  final String dateDebut;
  final String dateFin;
  final int nbNuits;
  final double totalCost;
  final StatutReservation statut;
  final ReservationBien bien;

  const Reservation({
    required this.idReservation,
    required this.dateDebut,
    required this.dateFin,
    required this.nbNuits,
    required this.totalCost,
    required this.statut,
    required this.bien,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final statutStr = json['statut'] as String? ?? 'a_venir';
    final statut = switch (statutStr) {
      'en_cours' => StatutReservation.enCours,
      'termine'  => StatutReservation.termine,
      _          => StatutReservation.aVenir,
    };

    return Reservation(
      idReservation: json['id_reservation'] as int,
      dateDebut:     json['date_debut']     as String? ?? '',
      dateFin:       json['date_fin']       as String? ?? '',
      nbNuits:       json['nb_nuits']       as int? ?? 0,
      totalCost:     (json['total_cost']    as num?)?.toDouble() ?? 0.0,
      statut:        statut,
      bien:          ReservationBien.fromJson(json['bien'] as Map<String, dynamic>),
    );
  }

  /// Libellé affiché du statut.
  String get statutLabel => switch (statut) {
        StatutReservation.aVenir  => 'À venir',
        StatutReservation.enCours => 'En cours',
        StatutReservation.termine => 'Terminé',
      };
}
