import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/api_config.dart';
import '../../models/bien.dart';
import '../../models/point_of_interest.dart';
import '../../services/poi_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const Color _bg = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent = Color(0xFFe94560);

  static const LatLng _defaultCenter = LatLng(46.603354, 1.888334);
  static const double _defaultZoom = 6.0;
  static const double _focusZoom = 13.0;
  static const double _locationZoom = 12.0;

  final MapController _mapController = MapController();

  List<Bien> _biens = [];
  List<PointOfInterest> _pois = [];
  bool _loading = true;
  bool _loadingPois = false;
  bool _showPois = false;
  bool _locating = false;
  String? _error;
  Bien? _selectedBien;
  LatLng? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadBiens();
    _initLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadBiens() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('${ApiConfig.biens}?per_page=100');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final list = (data['data'] as List<dynamic>)
              .map((item) => Bien.fromJson(Map<String, dynamic>.from(item as Map)))
              .where((bien) => bien.latCommune != null && bien.longCommune != null)
              .toList();
          if (!mounted) return;
          setState(() {
            _biens = list;
            _loading = false;
          });
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les biens.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur reseau. Verifiez votre connexion.';
        _loading = false;
      });
    }
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        await _fetchLocation(silent: true);
      }
    } catch (_) {}
  }

  Future<void> _fetchLocation({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _onLocationError('Le GPS est desactive.', silent: silent);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _onLocationError('Permission de localisation refusee.', silent: silent);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _onLocationError('Permission refusee definitivement.', silent: silent);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final location = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _userPosition = location;
        _locating = false;
      });
      _mapController.move(location, _locationZoom);
    } catch (_) {
      _onLocationError('Impossible de recuperer votre position.', silent: silent);
    }
  }

  void _onLocationError(String message, {bool silent = false}) {
    if (!mounted) return;
    setState(() => _locating = false);
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _surface,
        ),
      );
    }
  }

  void _onMarkerTap(Bien bien) {
    setState(() => _selectedBien = bien);
    _mapController.move(LatLng(bien.latCommune!, bien.longCommune!), _focusZoom);
    _showBienSheet(bien);
  }

  void _showBienSheet(Bien bien) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BienBottomSheet(
        bien: bien,
        userPosition: _userPosition,
        onNavigate: () {
          Navigator.of(ctx).pop();
          context.push('/bien/${bien.idBiens}', extra: bien);
        },
      ),
    ).whenComplete(() => setState(() => _selectedBien = null));
  }

  Future<void> _togglePois() async {
    if (_showPois) {
      setState(() => _showPois = false);
      return;
    }

    setState(() => _loadingPois = true);
    try {
      final center = _userPosition ?? _defaultCenter;
      final pois = await PoiService.fetchNearbyPois(center, radiusMeters: 100000);
      if (!mounted) return;
      setState(() {
        _pois = pois;
        _showPois = true;
        _loadingPois = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPois = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger les points d\'interet.'),
          backgroundColor: Color(0xFF16213e),
        ),
      );
    }
  }

  void _showPoiSheet(PointOfInterest poi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              if (poi.photos.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ApiConfig.photoUrl(poi.photos.first),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: _surface,
                      child: const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                ),
              if (poi.photos.isNotEmpty) const SizedBox(height: 12),
              Text(
                poi.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                poi.category,
                style: TextStyle(
                  color: _getPoiCategoryColor(poi.category),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (poi.address != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        poi.address!,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Latitude ${poi.latitude.toStringAsFixed(5)} • Longitude ${poi.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              if (poi.description != null && poi.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Description',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  poi.description!,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPoiCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('evenement')) return const Color(0xFF6c5ce7);
    if (lower.contains('restaurant') || lower.contains('cafe')) return const Color(0xFFe74c3c);
    if (lower.contains('pharmacie') || lower.contains('hospital')) return const Color(0xFF27ae60);
    if (lower.contains('parc') || lower.contains('leisure')) return const Color(0xFF16a085);
    if (lower.contains('musee') || lower.contains('museum') || lower.contains('attraction')) {
      return const Color(0xFFf39c12);
    }
    if (lower.contains('hotel')) return const Color(0xFF8e44ad);
    if (lower.contains('shopping') || lower.contains('commerce')) return const Color(0xFFe67e22);
    if (lower.contains('parking') || lower.contains('station')) return const Color(0xFF34495e);
    if (lower.contains('banque') || lower.contains('bank')) return const Color(0xFF2980b9);
    return const Color(0xFF95a5a6);
  }

  IconData _getPoiCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('evenement')) return Icons.event;
    if (lower.contains('restaurant')) return Icons.restaurant;
    if (lower.contains('cafe')) return Icons.local_cafe;
    if (lower.contains('pharmacie') || lower.contains('hospital')) return Icons.local_pharmacy;
    if (lower.contains('parc')) return Icons.park;
    if (lower.contains('musee') || lower.contains('museum') || lower.contains('attraction')) {
      return Icons.museum;
    }
    if (lower.contains('hotel')) return Icons.hotel;
    if (lower.contains('shopping') || lower.contains('commerce')) return Icons.shopping_bag;
    if (lower.contains('parking')) return Icons.directions_car;
    if (lower.contains('station')) return Icons.train;
    if (lower.contains('banque') || lower.contains('bank')) return Icons.account_balance;
    if (lower.contains('leisure')) return Icons.sports_bar;
    return Icons.place_outlined;
  }

  void _recenter() {
    if (_userPosition != null) {
      _mapController.move(_userPosition!, _locationZoom);
    } else {
      _mapController.move(_defaultCenter, _defaultZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          if (!_loading && _error == null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: _defaultZoom,
                onTap: (_, __) => setState(() => _selectedBien = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.hap_mobile',
                ),
                MarkerLayer(
                  markers: _biens.map((bien) {
                    final isSelected = _selectedBien?.idBiens == bien.idBiens;
                    return Marker(
                      point: LatLng(bien.latCommune!, bien.longCommune!),
                      width: isSelected ? 48 : 38,
                      height: isSelected ? 48 : 38,
                      child: GestureDetector(
                        onTap: () => _onMarkerTap(bien),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? _accent : _surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : _accent,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withAlpha(isSelected ? 120 : 60),
                                blurRadius: isSelected ? 10 : 4,
                                spreadRadius: isSelected ? 2 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.home,
                            color: isSelected ? Colors.white : _accent,
                            size: isSelected ? 24 : 18,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_showPois)
                  MarkerLayer(
                    markers: _pois.map((poi) {
                      final categoryColor = _getPoiCategoryColor(poi.category);
                      final categoryIcon = _getPoiCategoryIcon(poi.category);
                      return Marker(
                        point: LatLng(poi.latitude, poi.longitude),
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () => _showPoiSheet(poi),
                          child: Container(
                            decoration: BoxDecoration(
                              color: categoryColor.withAlpha(180),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white70, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(60),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              categoryIcon,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                if (_userPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _userPosition!,
                        width: 44,
                        height: 44,
                        child: const _UserLocationMarker(),
                      ),
                    ],
                  ),
              ],
            ),
          if (_loading) _buildShimmer(),
          if (_error != null) _buildError(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bg.withAlpha(230), _bg.withAlpha(0)],
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Carte des biens',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!_loading && _error == null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _surface.withAlpha(200),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withAlpha(100)),
                      ),
                      child: Text(
                        '${_biens.length} bien${_biens.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!_loading && _error == null)
            Positioned(
              bottom: 24,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'locate',
                    onPressed: _locating ? null : () => _fetchLocation(silent: false),
                    backgroundColor: _userPosition != null ? _accent : _surface,
                    foregroundColor: Colors.white,
                    tooltip: 'Me localiser',
                    child: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'recenter',
                    onPressed: _recenter,
                    backgroundColor: _surface,
                    foregroundColor: Colors.white,
                    tooltip: _userPosition != null ? 'Revenir a ma position' : 'Vue France',
                    child: const Icon(Icons.center_focus_strong),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'reload',
                    onPressed: _loadBiens,
                    backgroundColor: _surface,
                    foregroundColor: _accent,
                    tooltip: 'Recharger les biens',
                    child: const Icon(Icons.refresh),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'poi',
                    onPressed: _loadingPois ? null : _togglePois,
                    backgroundColor: _showPois ? _accent : _surface,
                    foregroundColor: Colors.white,
                    tooltip: _showPois ? 'Masquer les points d\'interet' : 'Afficher les points d\'interet',
                    child: _loadingPois
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.place_outlined),
                  ),
                ],
              ),
            ),
          if (_userPosition != null && !_loading && _error == null)
            Positioned(
              bottom: 24,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withAlpha(220),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Localise',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: _surface,
      highlightColor: const Color(0xFF0f3460),
      child: Container(
        color: _surface,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, color: Colors.white24, size: 64),
              SizedBox(height: 16),
              Text('Chargement de la carte...', style: TextStyle(color: Colors.white38, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: _bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white38, size: 56),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadBiens,
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserLocationMarker extends StatefulWidget {
  const _UserLocationMarker();

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 44 * _pulse.value,
            height: 44 * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withAlpha((80 * _pulse.value).toInt()),
            ),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade600,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withAlpha(120),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BienBottomSheet extends StatelessWidget {
  final Bien bien;
  final LatLng? userPosition;
  final VoidCallback onNavigate;

  static const Color _accent = Color(0xFFe94560);
  static const Color _surface = Color(0xFF16213e);

  const _BienBottomSheet({
    required this.bien,
    required this.userPosition,
    required this.onNavigate,
  });

  String? _distanceLabel() {
    if (userPosition == null || bien.latCommune == null || bien.longCommune == null) return null;
    final meters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      bien.latCommune!,
      bien.longCommune!,
    );
    return meters < 1000 ? '${meters.toStringAsFixed(0)} m' : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = ApiConfig.photoUrl(bien.photo);
    final distance = _distanceLabel();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bien.nomBiens,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (bien.nomCommune != null) ...[
                          const Text('📍 ', style: TextStyle(fontSize: 12)),
                          Flexible(
                            child: Text(
                              bien.communeLabel,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (distance != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(40),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              distance,
                              style: const TextStyle(
                                color: Colors.lightBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (bien.noteMoyenne != null)
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: bien.noteMoyenne!,
                            itemBuilder: (_, __) => const Icon(Icons.star, color: Color(0xFFFFD700)),
                            itemCount: 5,
                            itemSize: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${bien.noteMoyenne!.toStringAsFixed(1)} (${bien.nbAvis})',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${bien.tarifSemaine.toStringAsFixed(0)} € / sem.',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Voir le detail'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('🏠', style: TextStyle(fontSize: 32))),
      );
}
