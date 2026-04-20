class PointOfInterest {
  final int id;
  final String name;
  final String category;
  final String? description;
  final String? address;
  final double latitude;
  final double longitude;
  final List<String> photos;

  const PointOfInterest({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.description,
    this.address,
    this.photos = const [],
  });

  factory PointOfInterest.fromJson(Map<String, dynamic> json) {
    final rawId = json['id_poi'] ?? json['id'];
    final id = rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return PointOfInterest(
      id: id,
      name: json['nom_poi'] as String? ?? (json['name'] as String? ?? 'Point d\'interet'),
      category: json['categorie_poi'] as String? ?? (json['category'] as String? ?? 'Point d\'interet'),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String?,
      address: json['adresse'] as String? ?? json['address'] as String?,
      photos: List<String>.from(json['photos'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_poi': id,
    'nom_poi': name,
    'categorie_poi': category,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
    'adresse': address,
    'photos': photos,
  };
}