/// bien_card.dart — Carte Material Design d'un bien immobilier HAP
///
/// Affiche un [Bien] avec un design style Airbnb :
///   - Photo du bien avec fallback emoji 🏠
///   - Badge type de bien en overlay
///   - Bouton cœur favori avec animation
///   - Informations (nom, commune, note, prix, couchages, animaux)
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../config/api_config.dart';
import '../models/bien.dart';

/// Carte d'un bien immobilier avec actions favori et navigation.
class BienCard extends StatefulWidget {
  /// Le bien à afficher.
  final Bien bien;

  /// Callback déclenché au tap sur la carte.
  final VoidCallback? onTap;

  /// Callback déclenché lors du toggle favori.
  final ValueChanged<bool>? onFavoriToggle;

  const BienCard({
    super.key,
    required this.bien,
    this.onTap,
    this.onFavoriToggle,
  });

  @override
  State<BienCard> createState() => _BienCardState();
}

class _BienCardState extends State<BienCard>
    with SingleTickerProviderStateMixin {
  // ── Couleurs ──────────────────────────────────────────────────────────────
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  late bool _isFavorite;
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.bien.isFavorite;
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleFavori() async {
    setState(() => _isFavorite = !_isFavorite);
    widget.bien.isFavorite = _isFavorite;
    await _heartCtrl.forward();
    await _heartCtrl.reverse();
    widget.onFavoriToggle?.call(_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final bien = widget.bien;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _surface,
              const Color(0xFF101828),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + overlays ─────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: _buildImage(bien),
                ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Badge type de bien
                if (bien.designationTypeBien != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _bg.withAlpha(204),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        bien.designationTypeBien!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Bouton favori
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _toggleFavori,
                    child: ScaleTransition(
                      scale: _heartScale,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Icon(
                          _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isFavorite ? _accent : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Infos ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du bien
                  Text(
                    bien.nomBiens,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Commune
                  if (bien.nomCommune != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Colors.white54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              bien.communeLabel,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Note et avis
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: bien.noteMoyenne ?? 0,
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Color(0xFFFFD700),
                        ),
                        itemCount: 5,
                        itemSize: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        bien.noteMoyenne != null
                            ? '${bien.noteMoyenne!.toStringAsFixed(1)} (${bien.nbAvis})'
                            : 'Aucun avis',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Prix + couchages + animaux
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Prix
                      Text(
                        '${bien.tarifSemaine.toStringAsFixed(0)} € / sem.',
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Icônes couchages + animaux
                      Row(
                        children: [
                          const Text('🛏 ', style: TextStyle(fontSize: 13)),
                          Text(
                            '${bien.nbCouchage}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          if (bien.animauxAcceptes) ...[
                            const SizedBox(width: 8),
                            const Text('🐾', style: TextStyle(fontSize: 13)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit l'image du bien (avec cache) ou un placeholder emoji 🏠.
  Widget _buildImage(Bien bien) {
    if (bien.photo == null || bien.photo!.isEmpty) {
      return _placeholder();
    }

    // Construction de l'URL absolue si nécessaire
    final photoUrl = ApiConfig.photoUrl(bien.photo);

    
    return CachedNetworkImage(
      imageUrl: photoUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => _placeholder(loading: true),
      errorWidget: (context, url, error) => _placeholder(),
    );
  }

  /// Widget de remplacement quand aucune photo n'est disponible.
  Widget _placeholder({bool loading = false}) {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFF0f3460),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Color(0xFFe94560),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                '🏠',
                style: TextStyle(fontSize: 50),
              ),
      ),
    );
  }
}
