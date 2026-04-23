/// bien.dart — Modèle de données pour un Bien (propriété à louer)
///
/// Représente un bien immobilier retourné par [get_biens_mobile.php].
/// Inclut les informations de la commune, du type de bien,
/// la photo principale, la note moyenne et le tarif par semaine.
library;

class Bien {
  /// Identifiant unique du bien
  final int idBiens;

  /// Nom du bien (ex: "Villa Sunset")
  final String nomBiens;

  /// Adresse rue du bien
  final String rueBiens;

  /// Superficie en m²
  final double superficieBiens;

  /// Description détaillée
  final String? descriptionBiens;

  /// 1 si les animaux sont acceptés, 0 sinon
  final int animalBiens;

  /// Nombre de couchages disponibles
  final int nbCouchage;

  /// Désignation du type de bien (ex: "Villa", "Appartement")
  final String? designationTypeBien;

  /// Nom de la commune
  final String? nomCommune;

  /// Code postal de la commune
  final String? cpCommune;

  /// Latitude de la commune (pour la carte)
  final double? latCommune;

  /// Longitude de la commune (pour la carte)
  final double? longCommune;

  /// URL relative de la photo principale
  final String? photo;

  /// Note moyenne des avis (null si aucun avis)
  final double? noteMoyenne;

  /// Nombre d'avis validés
  final int nbAvis;

  /// Tarif par semaine en euros
  final double tarifSemaine;

  /// Indique si le bien est dans les favoris de l'utilisateur
  bool isFavorite;

  Bien({
    required this.idBiens,
    required this.nomBiens,
    required this.rueBiens,
    required this.superficieBiens,
    this.descriptionBiens,
    required this.animalBiens,
    required this.nbCouchage,
    this.designationTypeBien,
    this.nomCommune,
    this.cpCommune,
    this.latCommune,
    this.longCommune,
    this.photo,
    this.noteMoyenne,
    required this.nbAvis,
    required this.tarifSemaine,
    this.isFavorite = false,
  });

  /// Crée un [Bien] depuis un objet JSON (réponse de l'API).
  factory Bien.fromJson(Map<String, dynamic> json) {
    return Bien(
      idBiens: json['id_biens'] as int,
      nomBiens: json['nom_biens'] as String? ?? '',
      rueBiens: json['rue_biens'] as String? ?? '',
      superficieBiens: (json['superficie_biens'] as num?)?.toDouble() ?? 0.0,
      descriptionBiens: json['description_biens'] as String?,
      animalBiens: json['animal_biens'] as int? ?? 0,
      nbCouchage: json['nb_couchage'] as int? ?? 0,
      designationTypeBien: json['designation_type_bien'] as String?,
      nomCommune: json['nom_commune'] as String?,
      cpCommune: json['cp_commune'] as String?,
      latCommune: (json['lat_commune'] as num?)?.toDouble(),
      longCommune: (json['long_commune'] as num?)?.toDouble(),
      photo: json['photo'] as String?,
      noteMoyenne: (json['note_moyenne'] as num?)?.toDouble(),
      nbAvis: json['nb_avis'] as int? ?? 0,
      tarifSemaine: (json['tarif_semaine'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convertit le [Bien] en objet JSON.
  Map<String, dynamic> toJson() => {
        'id_biens': idBiens,
        'nom_biens': nomBiens,
        'rue_biens': rueBiens,
        'superficie_biens': superficieBiens,
        'description_biens': descriptionBiens,
        'animal_biens': animalBiens,
        'nb_couchage': nbCouchage,
        'designation_type_bien': designationTypeBien,
        'nom_commune': nomCommune,
        'cp_commune': cpCommune,
        'lat_commune': latCommune,
        'long_commune': longCommune,
        'photo': photo,
        'note_moyenne': noteMoyenne,
        'nb_avis': nbAvis,
        'tarif_semaine': tarifSemaine,
      };

  /// Retourne true si les animaux sont acceptés dans ce bien.
  bool get animauxAcceptes => animalBiens == 1;

  /// Retourne le label ville formaté "Nom (CP)".
  String get communeLabel {
    if (nomCommune == null) return '';
    if (cpCommune == null) return nomCommune!;
    return '$nomCommune ($cpCommune)';
  }
}
