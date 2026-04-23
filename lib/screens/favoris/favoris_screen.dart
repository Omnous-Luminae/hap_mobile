/// favoris_screen.dart — Écran Favoris HAP Mobile
///
/// - Charge les favoris via FavorisService.getFavoris()
/// - Affiche les biens en grille 2 colonnes
/// - Bouton cœur pour retirer un favori avec feedback immédiat
/// - Clic sur une carte → BienDetailScreen
/// - Pull-to-refresh, état vide, gestion erreur
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../services/app_preferences_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/favoris_service.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  List<Map<String, dynamic>> _favoris = [];
  bool _loading = true;
  String? _error;
  bool _compactLayout = false;

  // IDs en cours de suppression (pour désactiver le bouton pendant l'appel)
  final Set<int> _removing = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _load();
  }

  Future<void> _loadPreferences() async {
    final compactLayout = await AppPreferencesService.getCompactLayout();
    if (!mounted) return;
    setState(() => _compactLayout = compactLayout);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) {
        setState(() { _error = 'Connectez-vous pour voir vos favoris.'; _loading = false; });
        return;
      }
      final data = await FavorisService.getFavoris();
      setState(() { _favoris = data; _loading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _retirer(int idBiens) async {
    setState(() => _removing.add(idBiens));
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      await FavorisService.retirerFavori(idBiens: idBiens);
      setState(() => _favoris.removeWhere((f) => f['id_biens'] == idBiens));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retiré des favoris.'),
          backgroundColor: Color(0xFF16213e),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFe94560),
        ),
      );
    } finally {
      if (mounted) setState(() => _removing.remove(idBiens));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bg, Color(0xFF101828)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          title: const Row(
            children: [
              Icon(Icons.favorite, color: _accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Mes favoris',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              tooltip: 'Actualiser',
              onPressed: _load,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _accent),
      );
    }

    if (_error != null) {
      return _SectionShell(
        icon: Icons.wifi_off,
        title: 'Impossible de charger vos favoris',
        message: _error!,
        actionLabel: 'Réessayer',
        onAction: _load,
      );
    }

    if (_favoris.isEmpty) {
      return _SectionShell(
        icon: Icons.favorite_border,
        title: 'Aucun favori pour le moment',
        message: 'Ajoutez un bien à vos favoris pour le retrouver plus vite.',
        actionLabel: 'Explorer les biens',
        onAction: () => context.go('/home'),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFFe94560),
      backgroundColor: const Color(0xFF16213e),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width < 380
              ? 1
              : width < 720
                  ? 2
                  : 3;
          final childAspectRatio = crossAxisCount == 1
              ? (_compactLayout ? 0.74 : 0.78)
              : (_compactLayout ? 0.76 : 0.80);

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    width >= 600 ? 24 : 16,
                    16,
                    width >= 600 ? 24 : 16,
                    12,
                  ),
                  child: _SummaryCard(count: _favoris.length),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  width >= 600 ? 24 : 16,
                  0,
                  width >= 600 ? 24 : 16,
                  16,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final f = _favoris[i];
                      final id = f['id_biens'] as int;
                      return _FavoriCard(
                        favori: f,
                        isRemoving: _removing.contains(id),
                        onTap: () => context.push('/bien/$id'),
                        onRetirer: () => _retirer(id),
                      );
                    },
                    childCount: _favoris.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionShell({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _FavorisScreenState._surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Icon(icon, color: _FavorisScreenState._accent, size: 42),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: _FavorisScreenState._accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int count;

  const _SummaryCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF16213e),
            const Color(0xFF16213e).withAlpha(220),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFe94560).withAlpha(40),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.favorite, color: _FavorisScreenState._accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count favori${count > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Glissez vers le bas pour actualiser la liste.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte favori ───────────────────────────────────────────────────────────

class _FavoriCard extends StatelessWidget {
  final Map<String, dynamic> favori;
  final bool isRemoving;
  final VoidCallback onTap;
  final VoidCallback onRetirer;

  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  const _FavoriCard({
    required this.favori,
    required this.isRemoving,
    required this.onTap,
    required this.onRetirer,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl   = ApiConfig.photoUrl(favori['photo'] as String?);
    final note       = (favori['note_moyenne'] as num?)?.toDouble();
    final nbAvis     = favori['nb_avis'] as int? ?? 0;
    final tarif      = (favori['tarif_semaine'] as num?)?.toDouble() ?? 0.0;
    final nomBiens   = favori['nom_biens'] as String? ?? '';
    final commune    = favori['nom_commune'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo + bouton retirer
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                // Bouton cœur
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: isRemoving ? null : onRetirer,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        shape: BoxShape.circle,
                      ),
                      child: isRemoving
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.favorite,
                              color: Color(0xFFe94560), size: 16),
                    ),
                  ),
                ),
              ],
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomBiens,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (commune != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📍 $commune',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 4),
                  if (note != null)
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: note,
                          itemBuilder: (_, _) => const Icon(
                              Icons.star, color: Color(0xFFFFD700)),
                          itemCount: 5,
                          itemSize: 11,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '($nbAvis)',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${tarif.toStringAsFixed(0)} € / sem.',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF0f3460),
        child:
            const Center(child: Text('🏠', style: TextStyle(fontSize: 32))),
      );
}