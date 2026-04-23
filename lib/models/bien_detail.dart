/// bien_detail.dart — Modèle détaillé d'un bien avec photos, avis et tarifs
library;

import 'bien.dart';

/// Photo d'un bien.
class BienPhoto {
  final int idPhoto;
  final String nomPhotos;
  final String lienPhoto;

  const BienPhoto({
    required this.idPhoto,
    required this.nomPhotos,
    required this.lienPhoto,
  });

  factory BienPhoto.fromJson(Map<String, dynamic> json) => BienPhoto(
        idPhoto:   json['id_photo']   as int,
        nomPhotos: json['nom_photos'] as String? ?? '',
        lienPhoto: json['lien_photo'] as String? ?? '',
      );
}

/// Avis d'un locataire sur un bien.
class Avis {
  final int idReview;
  final int rating;
  final String content;
  final String createdAt;
  final String auteur;

  const Avis({
    required this.idReview,
    required this.rating,
    required this.content,
    required this.createdAt,
    required this.auteur,
  });

  factory Avis.fromJson(Map<String, dynamic> json) => Avis(
        idReview:  json['id_review'] as int,
        rating:    json['rating']    as int,
        content:   json['content']   as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        auteur:    json['auteur']    as String?  ?? 'Utilisateur',
      );
}

/// Tarif hebdomadaire d'un bien pour une semaine et année données.
class TarifSemaine {
  final int idTarif;
  final double semaine;
  final int annee;
  final double tarif;
  final String libSaison;

  const TarifSemaine({
    required this.idTarif,
    required this.semaine,
    required this.annee,
    required this.tarif,
    required this.libSaison,
  });

  factory TarifSemaine.fromJson(Map<String, dynamic> json) => TarifSemaine(
        idTarif:   json['id_Tarif']     as int,
        semaine:   (json['semaine_Tarif'] as num).toDouble(),
        annee:     json['annee']        as int,
        tarif:     (json['tarif']       as num).toDouble(),
        libSaison: json['lib_saison']   as String? ?? '',
      );
}

/// Vue complète d'un bien avec toutes ses données (photos, avis, tarifs).
class BienDetail extends Bien {
  final List<BienPhoto> photos;
  final List<Avis> avis;
  final List<TarifSemaine> tarifs;

  BienDetail({
    required super.idBiens,
    required super.nomBiens,
    required super.rueBiens,
    required super.superficieBiens,
    super.descriptionBiens,
    required super.animalBiens,
    required super.nbCouchage,
    super.designationTypeBien,
    super.nomCommune,
    super.cpCommune,
    super.latCommune,
    super.longCommune,
    super.photo,
    super.noteMoyenne,
    required super.nbAvis,
    required super.tarifSemaine,
    super.isFavorite = false,
    required this.photos,
    required this.avis,
    required this.tarifs,
  });

  factory BienDetail.fromJson(Map<String, dynamic> json) {
    final rawPhotos = (json['photos'] as List<dynamic>?) ?? [];
    final rawAvis   = (json['avis']   as List<dynamic>?) ?? [];
    final rawTarifs = (json['tarifs'] as List<dynamic>?) ?? [];

    final photosList = rawPhotos
        .map((e) => BienPhoto.fromJson(e as Map<String, dynamic>))
        .toList();

    final tarifsList = rawTarifs
        .map((e) => TarifSemaine.fromJson(e as Map<String, dynamic>))
        .toList();

    // Derive tarif_semaine: first future tarif or 0
    final tarifSemaine = tarifsList.isNotEmpty ? tarifsList.first.tarif : 0.0;

    return BienDetail(
      idBiens:             json['id_biens']             as int,
      nomBiens:            json['nom_biens']             as String? ?? '',
      rueBiens:            json['rue_biens']             as String? ?? '',
      superficieBiens:     (json['superficie_biens']     as num?)?.toDouble() ?? 0.0,
      descriptionBiens:    json['description_biens']     as String?,
      animalBiens:         json['animal_biens']          as int? ?? 0,
      nbCouchage:          json['nb_couchage']           as int? ?? 0,
      designationTypeBien: json['designation_type_bien'] as String?,
      nomCommune:          json['nom_commune']           as String?,
      cpCommune:           json['cp_commune']            as String?,
      latCommune:          (json['lat_commune']          as num?)?.toDouble(),
      longCommune:         (json['long_commune']         as num?)?.toDouble(),
      photo:               photosList.isNotEmpty ? photosList.first.lienPhoto : null,
      noteMoyenne:         (json['note_moyenne']         as num?)?.toDouble(),
      nbAvis:              json['nb_avis']               as int? ?? 0,
      tarifSemaine:        tarifSemaine,
      photos:              photosList,
      avis:                rawAvis
          .map((e) => Avis.fromJson(e as Map<String, dynamic>))
          .toList(),
      tarifs:              tarifsList,
    );
  }

  /// Retourne le tarif applicable pour la date donnée.
  /// Si aucun tarif n'est trouvé, retourne null.
  double? tarifPourDate(DateTime date) {
    if (tarifs.isEmpty) return null;
    final week  = _isoWeek(date);
    final annee = _isoYear(date);
    // Exact match first
    for (final t in tarifs) {
      if (t.annee == annee && t.semaine.round() == week) return t.tarif;
    }
    // Fallback: first available
    return tarifs.first.tarif;
  }

  static int _isoWeek(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear   = date.difference(startOfYear).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  static int _isoYear(DateTime date) => date.year;
}
