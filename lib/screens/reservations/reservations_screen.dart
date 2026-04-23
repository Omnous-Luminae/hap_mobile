// ═════════════════════════════════════════════════════════════════════════════
// reservations_screen.dart — Liste des réservations avec annulation
// ═════════════════════════════════════════════════════════════════════════════

/// reservations_screen.dart — Liste des réservations de l'utilisateur connecté
///
/// - Charge les réservations via ReservationService.getMesReservations()
/// - Affiche les cartes avec statut (à venir / en cours / terminé)
/// - Bouton annuler sur les réservations "à venir" uniquement
/// - Pull-to-refresh
library;


import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../models/reservation.dart';
import '../../services/app_preferences_service.dart';
import '../../services/reservation_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  late Future<List<Reservation>> _future;
  bool _compactLayout = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _future = ReservationService.getMesReservations();
  }

  Future<void> _loadPreferences() async {
    final compactLayout = await AppPreferencesService.getCompactLayout();
    if (!mounted) return;
    setState(() => _compactLayout = compactLayout);
  }

  void _refresh() => setState(() {
        _future = ReservationService.getMesReservations();
      });

  Future<void> _annuler(Reservation r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Annuler la réservation',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Voulez-vous annuler la réservation pour "${r.bien.nomBiens}" du ${_fmt(r.dateDebut)} au ${_fmt(r.dateFin)} ?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Annuler la réservation',
                style: TextStyle(color: Color(0xFFe94560))),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ReservationService.cancelReservation(
        idReservation: r.idReservation,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation annulée.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFe94560),
        ),
      );
    }
  }

  String _fmt(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('d MMM yyyy', 'fr_FR').format(d);
    } catch (_) {
      return iso;
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
              Icon(Icons.calendar_month, color: _accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Mes réservations',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              tooltip: 'Actualiser',
              onPressed: _refresh,
            ),
          ],
        ),
        body: FutureBuilder<List<Reservation>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _accent),
              );
            }
            if (snap.hasError) {
              return _buildError(
                snap.error.toString().replaceFirst('Exception: ', ''),
              );
            }

            final list = snap.data ?? [];
            if (list.isEmpty) return _buildEmpty();

            return LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth > 760 ? 760.0 : constraints.maxWidth;
                final compact = _compactLayout || constraints.maxWidth < 360;

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: RefreshIndicator(
                      color: _accent,
                      onRefresh: () async => _refresh(),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                maxWidth >= 700 ? 24 : 16,
                                16,
                                maxWidth >= 700 ? 24 : 16,
                                12,
                              ),
                              child: _SummaryCard(reservations: list, compact: compact),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              maxWidth >= 700 ? 24 : 16,
                              0,
                              maxWidth >= 700 ? 24 : 16,
                              16,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: i == list.length - 1 ? 0 : 12,
                                  ),
                                  child: _ReservationCard(
                                    reservation: list[i],
                                    compact: compact,
                                    onTap: () => context.push('/bien/${list[i].bien.idBiens}'),
                                    onAnnuler: list[i].statut == StatutReservation.aVenir
                                        ? () => _annuler(list[i])
                                        : null,
                                  ),
                                ),
                                childCount: list.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📅', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              const Text('Aucune réservation',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Vos futures réservations apparaîtront ici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.search),
                label: const Text('Explorer les biens'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _refresh,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _accent, foregroundColor: Colors.white),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  final List<Reservation> reservations;
  final bool compact;

  const _SummaryCard({required this.reservations, required this.compact});

  @override
  Widget build(BuildContext context) {
    final upcoming = reservations.where((r) => r.statut == StatutReservation.aVenir).length;
    final total = reservations.length;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
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
            width: compact ? 40 : 44,
            height: compact ? 40 : 44,
            decoration: BoxDecoration(
              color: const Color(0xFFe94560).withAlpha(40),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calendar_month, color: Color(0xFFe94560)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total réservation${total > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$upcoming à venir, le reste est déjà passé ou en cours.',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte réservation ──────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback? onAnnuler;

  const _ReservationCard({
    required this.reservation,
    required this.compact,
    required this.onTap,
    this.onAnnuler,
  });

  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  @override
  Widget build(BuildContext context) {
    final r    = reservation;
    final fmt  = DateFormat('d MMM yyyy', 'fr_FR');
    final fmtM = NumberFormat.currency(
        locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    final debut = DateTime.tryParse(r.dateDebut) ?? DateTime.now();
    final fin   = DateTime.tryParse(r.dateFin)   ?? DateTime.now();

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              color: Colors.black.withAlpha(60),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo + statut
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    height: compact ? 136 : 148,
                    width: double.infinity,
                    child: r.bien.photo != null && r.bien.photo!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ApiConfig.photoUrl(r.bien.photo),
                            fit: BoxFit.cover,
                            placeholder: (_, _) => _fallbackPhoto(loading: true),
                            errorWidget: (_, _, _) => _fallbackPhoto(),
                          )
                        : _fallbackPhoto(),
                  ),
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
                            Colors.black.withAlpha(115),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _StatutBadge(statut: r.statut),
                ),
              ],
            ),

            // Infos
            Padding(
              padding: EdgeInsets.all(compact ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.bien.nomBiens,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (r.bien.nomCommune != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: _accent),
                        const SizedBox(width: 4),
                        Text(r.bien.nomCommune!,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _infoChip(Icons.calendar_today, fmt.format(debut)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward,
                            size: 14, color: Colors.white38),
                      ),
                      _infoChip(Icons.calendar_today, fmt.format(fin)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${r.nbNuits} nuit${r.nbNuits > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                      ),
                      Text(
                        fmtM.format(r.totalCost),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  // Bouton annuler — visible uniquement pour "à venir"
                  if (onAnnuler != null) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onAnnuler,
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Annuler la réservation'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accent,
                          side: const BorderSide(color: Color(0xFFe94560)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackPhoto({bool loading = false}) => Container(
        color: const Color(0xFF0d1020),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                )
              : const Text('🏠', style: TextStyle(fontSize: 48)),
        ),
      );

  Widget _infoChip(IconData icon, String label) => Row(
        children: [
          Icon(icon, size: 12, color: Colors.white38),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );
}

// ── Badge statut ───────────────────────────────────────────────────────────

class _StatutBadge extends StatelessWidget {
  final StatutReservation statut;
  const _StatutBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (statut) {
      StatutReservation.aVenir  => ('À venir',  Colors.blue.shade400),
      StatutReservation.enCours => ('En cours', Colors.green.shade400),
      StatutReservation.termine => ('Terminé',  Colors.grey.shade500),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11)),
    );
  }
}