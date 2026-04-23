/// filter_options.dart — Classe de filtres pour la liste des biens
///
/// Encapsule tous les paramètres de filtrage disponibles dans l'API
/// [get_biens_mobile.php] et fournit [toQueryParams] pour les convertir
/// en paramètres d'URL.
library;

/// Options de tri disponibles.
enum SortOption {
  /// Mieux notés en premier (défaut)
  noteDesc,

  /// Prix croissant
  prixAsc,

  /// Prix décroissant
  prixDesc,

  /// Plus récents en premier
  recents,
}

/// Extension utilitaire sur [SortOption].
extension SortOptionExt on SortOption {
  /// Valeur envoyée à l'API.
  String get apiValue => switch (this) {
        SortOption.noteDesc => 'note_desc',
        SortOption.prixAsc  => 'prix_asc',
        SortOption.prixDesc => 'prix_desc',
        SortOption.recents  => 'recents',
      };

  /// Label lisible pour l'UI.
  String get label => switch (this) {
        SortOption.noteDesc => 'Mieux notés',
        SortOption.prixAsc  => 'Prix croissant',
        SortOption.prixDesc => 'Prix décroissant',
        SortOption.recents  => 'Plus récents',
      };
}

/// Classe immuable (snapshot) des critères de recherche et de filtrage.
class FilterOptions {
  /// ID de la commune sélectionnée (null = toutes communes)
  final int? communeId;

  /// ID du type de bien (null = tous types)
  final int? typeBien;

  /// Nombre minimum de couchages
  final int? nbCouchageMin;

  /// Nombre maximum de couchages
  final int? nbCouchageMax;

  /// Superficie minimale en m²
  final double? superficieMin;

  /// Superficie maximale en m²
  final double? superficieMax;

  /// true = animaux seulement, false = tous, null = tous
  final bool? animaux;

  /// Prix minimum par semaine en €
  final double? prixMin;

  /// Prix maximum par semaine en €
  final double? prixMax;

  /// Note minimale (1.0 – 5.0)
  final double? noteMin;

  /// Texte de recherche sur nom_biens
  final String? search;

  /// Critère de tri
  final SortOption sort;

  const FilterOptions({
    this.communeId,
    this.typeBien,
    this.nbCouchageMin,
    this.nbCouchageMax,
    this.superficieMin,
    this.superficieMax,
    this.animaux,
    this.prixMin,
    this.prixMax,
    this.noteMin,
    this.search,
    this.sort = SortOption.noteDesc,
  });

  /// Filtre vide (tous les biens, tri par note).
  const FilterOptions.empty() : this();

  /// Retourne le nombre de filtres actifs (hors tri).
  int get activeCount {
    int count = 0;
    if (typeBien != null) count++;
    if (prixMin != null || prixMax != null) count++;
    if (nbCouchageMin != null) count++;
    if (animaux == true) count++;
    if (superficieMin != null || superficieMax != null) count++;
    if (noteMin != null) count++;
    if (communeId != null) count++;
    return count;
  }

  /// Retourne true si aucun filtre n'est actif.
  bool get isEmpty => activeCount == 0 && (search == null || search!.isEmpty);

  /// Convertit les filtres en [Map<String, String>] pour les paramètres d'URL.
  Map<String, String> toQueryParams() {
    final params = <String, String>{};

    if (communeId != null) params['commune_id'] = communeId.toString();
    if (typeBien != null) params['type_bien'] = typeBien.toString();
    if (nbCouchageMin != null) params['nb_couchage_min'] = nbCouchageMin.toString();
    if (nbCouchageMax != null) params['nb_couchage_max'] = nbCouchageMax.toString();
    if (superficieMin != null) params['superficie_min'] = superficieMin!.toStringAsFixed(0);
    if (superficieMax != null) params['superficie_max'] = superficieMax!.toStringAsFixed(0);
    if (animaux != null) params['animaux'] = animaux! ? '1' : '0';
    if (prixMin != null) params['prix_min'] = prixMin!.toStringAsFixed(0);
    if (prixMax != null) params['prix_max'] = prixMax!.toStringAsFixed(0);
    if (noteMin != null) params['note_min'] = noteMin!.toStringAsFixed(1);
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    params['sort'] = sort.apiValue;

    return params;
  }

  /// Retourne une copie avec certains champs modifiés.
  FilterOptions copyWith({
    int? communeId,
    bool clearCommuneId = false,
    int? typeBien,
    bool clearTypeBien = false,
    int? nbCouchageMin,
    bool clearNbCouchageMin = false,
    int? nbCouchageMax,
    bool clearNbCouchageMax = false,
    double? superficieMin,
    bool clearSuperficieMin = false,
    double? superficieMax,
    bool clearSuperficieMax = false,
    bool? animaux,
    bool clearAnimaux = false,
    double? prixMin,
    bool clearPrixMin = false,
    double? prixMax,
    bool clearPrixMax = false,
    double? noteMin,
    bool clearNoteMin = false,
    String? search,
    bool clearSearch = false,
    SortOption? sort,
  }) {
    return FilterOptions(
      communeId:     clearCommuneId    ? null : communeId    ?? this.communeId,
      typeBien:      clearTypeBien     ? null : typeBien      ?? this.typeBien,
      nbCouchageMin: clearNbCouchageMin ? null : nbCouchageMin ?? this.nbCouchageMin,
      nbCouchageMax: clearNbCouchageMax ? null : nbCouchageMax ?? this.nbCouchageMax,
      superficieMin: clearSuperficieMin ? null : superficieMin ?? this.superficieMin,
      superficieMax: clearSuperficieMax ? null : superficieMax ?? this.superficieMax,
      animaux:       clearAnimaux      ? null : animaux       ?? this.animaux,
      prixMin:       clearPrixMin      ? null : prixMin       ?? this.prixMin,
      prixMax:       clearPrixMax      ? null : prixMax       ?? this.prixMax,
      noteMin:       clearNoteMin      ? null : noteMin       ?? this.noteMin,
      search:        clearSearch       ? null : search        ?? this.search,
      sort:          sort              ?? this.sort,
    );
  }
}
