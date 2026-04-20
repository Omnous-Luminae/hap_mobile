import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/api_config.dart';
import '../models/point_of_interest.dart';

class PoiService {
  static Future<List<PointOfInterest>> fetchNearbyPois(
    LatLng center, {
    int radiusMeters = 2500,
    String? category,
  }) async {
    try {
      return await _fetchFromDatabase(center, radiusMeters, category);
    } catch (_) {
      return _fetchFromOverpass(center, radiusMeters);
    }
  }

  static Future<List<PointOfInterest>> _fetchFromDatabase(
    LatLng center,
    int radiusMeters,
    String? category,
  ) async {
    final uri = Uri.parse(ApiConfig.pois).replace(
      queryParameters: {
        'latitude': center.latitude.toString(),
        'longitude': center.longitude.toString(),
        'radius': radiusMeters.toString(),
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('POI API error');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      throw Exception('Invalid POI payload');
    }

    final rawList = (decoded['data'] as List<dynamic>? ?? const []);
    return rawList
        .map((item) => PointOfInterest.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static Future<List<PointOfInterest>> _fetchFromOverpass(
    LatLng center,
    int radiusMeters,
  ) async {
    final query = '''
[out:json][timeout:25];
(
  node(around:$radiusMeters,${center.latitude},${center.longitude})["amenity"];
  node(around:$radiusMeters,${center.latitude},${center.longitude})["tourism"];
  node(around:$radiusMeters,${center.latitude},${center.longitude})["leisure"];
  node(around:$radiusMeters,${center.latitude},${center.longitude})["shop"];
);
out body 40;
''';

    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      headers: const {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
      body: 'data=${Uri.encodeComponent(query)}',
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les points d\'interet.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (decoded['elements'] as List<dynamic>?) ?? const [];

    return elements.map((element) {
      final map = Map<String, dynamic>.from(element as Map);
      final tags = Map<String, dynamic>.from(map['tags'] as Map? ?? const {});
      final category = _categoryFromTags(tags);
      return PointOfInterest(
        id: '${map['type']}-${map['id']}'.hashCode,
        name: (tags['name'] as String?) ?? category,
        category: category,
        latitude: (map['lat'] as num).toDouble(),
        longitude: (map['lon'] as num).toDouble(),
      );
    }).toList();
  }

  static String _categoryFromTags(Map<String, dynamic> tags) {
    final amenity = tags['amenity'] as String?;
    final tourism = tags['tourism'] as String?;
    final leisure = tags['leisure'] as String?;
    final shop = tags['shop'] as String?;

    if (amenity != null) return _friendlyAmenity(amenity);
    if (tourism != null) return _friendlyTourism(tourism);
    if (leisure != null) return _friendlyLeisure(leisure);
    if (shop != null) return 'Commerce';
    return 'Point d\'interet';
  }

  static String _friendlyAmenity(String value) {
    switch (value) {
      case 'parking':
        return 'Parking';
      case 'restaurant':
        return 'Restaurant';
      case 'cafe':
        return 'Cafe';
      case 'pharmacy':
        return 'Pharmacie';
      case 'bus_station':
        return 'Bus';
      case 'fuel':
        return 'Station-service';
      case 'bank':
        return 'Banque';
      case 'hospital':
        return 'Hopital';
      default:
        return 'Service';
    }
  }

  static String _friendlyTourism(String value) {
    switch (value) {
      case 'hotel':
        return 'Hotel';
      case 'attraction':
        return 'Attraction';
      case 'museum':
        return 'Musee';
      case 'viewpoint':
        return 'Point de vue';
      default:
        return 'Tourisme';
    }
  }

  static String _friendlyLeisure(String value) {
    switch (value) {
      case 'park':
        return 'Parc';
      case 'playground':
        return 'Jeux';
      case 'sports_centre':
        return 'Sport';
      default:
        return 'Loisir';
    }
  }
}
