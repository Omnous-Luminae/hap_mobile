/// bien_detail_screen.dart — Écran de détail d'un bien immobilier HAP Mobile
///
/// Design type Airbnb / Booking :
///   - Carrousel de photos plein écran en SliverAppBar
///   - Infos principales (nom, type, commune, rating, superficie, couchages)
///   - Description complète
///   - Carte interactive (flutter_map)
///   - Avis des locataires avec étoiles
///   - Barre sticky bas : prix/semaine + bouton Réserver
///   - Calendrier de disponibilité (bottom sheet)
///   - Formulaire de confirmation (bottom sheet)
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../config/api_config.dart';
import '../../models/bien.dart';
import '../../models/bien_detail.dart';
import '../../services/reservation_service.dart';
import '../../widgets/calendrier_disponibilites.dart';
import 'reservation_form_sheet.dart';

class BienDetailScreen extends StatefulWidget {
  /// ID du bien (depuis la route).
  final int id;

  /// Bien initial passé en extra (pour affichage immédiat avant le chargement complet).
  final Bien? initialBien;

  const BienDetailScreen({
    super.key,
    required this.id,
    this.initialBien,
  });

  @override
  State<BienDetailScreen> createState() => _BienDetailScreenState();
}

class _BienDetailScreenState extends State<BienDetailScreen> {
  // ── Couleurs ───────────────────────────────────────────────────────────────
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  // ── État ───────────────────────────────────────────────────────────────────
  BienDetail? _detail;
  bool        _isLoading       = true;
  bool        _isLoadingDispos  = false;
  String?     _error;
  int         _photoIndex       = 0;
  final _carouselController = CarouselSliderController();

  // Ranges réservées pour le calendrier
  List<Map<String, String>> _reservedRanges = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final detail = await ReservationService.getBienDetail(widget.id);
      if (!mounted) return;
      setState(() { _detail = detail; _isLoading = false; });
      _loadDisponibilites();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDisponibilites() async {
    setState(() => _isLoadingDispos = true);
    try {
      final ranges = await ReservationService.getDisponibilites(widget.id);
      if (!mounted) return;
      setState(() { _reservedRanges = ranges; _isLoadingDispos = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingDispos = false);
    }
  }

  // ── Ouverture du calendrier puis du formulaire ─────────────────────────────
  Future<void> _openReservation() async {
    if (_detail == null) return;

    final selected = await showCalendrierDisponibilites(
      context: context,
      bien: _detail!,
      reservedRanges: _reservedRanges,
    );

    if (selected == null || !mounted) return;

    final (debut, fin) = selected;

    final confirmed = await showReservationFormSheet(
      context: context,
      bien: _detail!,
      dateDebut: debut,
      dateFin:   fin,
    );

    if (!mounted) return;

    if (confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Réservation confirmée ! Consultez vos réservations.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      // Recharger les dispos après réservation
      _loadDisponibilites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _isLoading ? _buildLoader() : _buildContent(),
    );
  }

  // ── Loader ─────────────────────────────────────────────────────────────────
  Widget _buildLoader() => const Center(
        child: CircularProgressIndicator(color: _accent),
      );

  // ── Contenu principal ──────────────────────────────────────────────────────
  Widget _buildContent() {
    if (_error != null) return _buildError();
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
        _buildStickyBottomBar(),
      ],
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white38, size: 72),
              const SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );

  // ── SliverAppBar avec carrousel ────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    final photos = _detail?.photos ?? [];

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: _surface,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black54,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: photos.isEmpty
            ? _buildPhotoFallback()
            : _buildPhotoCarousel(photos),
      ),
    );
  }

  Widget _buildPhotoCarousel(List<BienPhoto> photos) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: photos.length,
          itemBuilder: (_, i, _) {
            final url = ApiConfig.photoUrl(photos[i].lienPhoto);
            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => _buildPhotoFallback(),
            );
          },
          options: CarouselOptions(
            height: double.infinity,
            viewportFraction: 1.0,
            enableInfiniteScroll: photos.length > 1,
            scrollDirection: Axis.horizontal,
            autoPlay: false,
            pauseAutoPlayOnTouch: true,
            scrollPhysics: const ClampingScrollPhysics(),
            onPageChanged: (i, _) => setState(() => _photoIndex = i),
          ),
        ),
        // Dégradé bas
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withAlpha(180)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Indicateur de pages
        if (photos.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  _photoIndex == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _photoIndex == i ? _accent : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        // Compteur
        Positioned(
          bottom: 12,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_photoIndex + 1}/${photos.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        // Boutons de navigation (précédent/suivant)
        if (photos.length > 1) ...[
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _carouselController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accent, _accent.withAlpha(204)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withAlpha(120),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _carouselController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accent, _accent.withAlpha(204)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withAlpha(120),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoFallback() => Container(
        color: _surface,
        child: const Center(
          child: Text('🏠', style: TextStyle(fontSize: 80)),
        ),
      );

  // ── Corps ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    final d = _detail!;
    final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 100), // espace pour la sticky bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Section : Titre & type ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.designationTypeBien != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accent.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accent.withAlpha(80)),
                    ),
                    child: Text(
                      d.designationTypeBien!,
                      style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  d.nomBiens,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                if (d.nomCommune != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: _accent),
                      const SizedBox(width: 4),
                      Text(
                        '${d.nomCommune}${d.cpCommune != null ? ' — ${d.cpCommune}' : ''}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─ Stats chips ────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _statChip(Icons.bed_outlined, '${d.nbCouchage} couchage${d.nbCouchage > 1 ? 's' : ''}'),
                const SizedBox(width: 8),
                _statChip(Icons.straighten, '${d.superficieBiens.toStringAsFixed(0)} m²'),
                const SizedBox(width: 8),
                _statChip(
                  d.animalBiens == 1 ? Icons.pets : Icons.do_not_touch,
                  d.animalBiens == 1 ? 'Animaux OK' : 'Sans animaux',
                  color: d.animalBiens == 1 ? Colors.green.shade400 : Colors.orange.shade300,
                ),
                if (d.noteMoyenne != null) ...[
                  const SizedBox(width: 8),
                  _statChip(Icons.star, '${d.noteMoyenne!.toStringAsFixed(1)} (${d.nbAvis} avis)', color: Colors.amber),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white12, indent: 20, endIndent: 20),

          // ─ Description ────────────────────────────────────────────────
          if (d.descriptionBiens != null && d.descriptionBiens!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Description'),
                  const SizedBox(height: 10),
                  _ExpandableText(d.descriptionBiens!),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12, indent: 20, endIndent: 20),
          ],

          // ─ Tarifs disponibles ────────────────────────────────────────
          if (d.tarifs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Tarifs'),
                  const SizedBox(height: 10),
                  ...d.tarifs.take(3).map((t) => _tarifRow(t, fmt)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12, indent: 20, endIndent: 20),
          ],

          // ─ Carte ─────────────────────────────────────────────────────
          if (d.latCommune != null && d.longCommune != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Localisation'),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(d.latCommune!, d.longCommune!),
                          initialZoom: 13,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(d.latCommune!, d.longCommune!),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: _accent,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12, indent: 20, endIndent: 20),
          ],

          // ─ Avis ──────────────────────────────────────────────────────
          if (d.avis.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _sectionTitle('Avis'),
                      const SizedBox(width: 8),
                      if (d.noteMoyenne != null)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${d.noteMoyenne!.toStringAsFixed(1)} · ${d.nbAvis} avis',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...d.avis.map((a) => _AvisCard(avis: a)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  // ── Sticky bottom bar ──────────────────────────────────────────────────────
  Widget _buildStickyBottomBar() {
    final d = _detail;
    if (d == null) return const SizedBox();

    final tarif = d.tarifs.isNotEmpty ? d.tarifs.first.tarif : d.tarifSemaine;
    final fmt   = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 0);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tarif > 0
                          ? fmt.format(tarif)
                          : 'Sur demande',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tarif > 0)
                      const Text(
                        '/ semaine',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoadingDispos ? null : _openReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        disabledBackgroundColor: Colors.white12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoadingDispos
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_month, size: 18, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Réserver',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _statChip(IconData icon, String label, {Color color = Colors.white70}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      );

  Widget _tarifRow(TarifSemaine t, NumberFormat fmt) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accent.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'S${t.semaine.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.libSaison,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  Text(
                    'Semaine ${t.semaine.toStringAsFixed(0)} — ${t.annee}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              fmt.format(t.tarif),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}

// ── Widget avis ────────────────────────────────────────────────────────────

class _AvisCard extends StatelessWidget {
  final Avis avis;
  const _AvisCard({required this.avis});

  static const Color _surface = Color(0xFF16213e);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF0d1020),
                child: Text(
                  avis.auteur.isNotEmpty ? avis.auteur[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avis.auteur,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    RatingBarIndicator(
                      rating: avis.rating.toDouble(),
                      itemSize: 14,
                      itemBuilder: (_, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                    ),
                  ],
                ),
              ),
              Text(
                _fmtDate(avis.createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            avis.content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(String raw) {
    try {
      return DateFormat('MMM yyyy', 'fr_FR').format(DateTime.parse(raw));
    } catch (_) {
      return raw.substring(0, 7);
    }
  }
}

// ── Widget texte expandable ────────────────────────────────────────────────

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText(this.text);

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const maxLines = 4;
    const accent   = Color(0xFFe94560);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : maxLines,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        if (widget.text.length > 200) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Voir moins' : 'Voir plus',
              style: const TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
