/// reservation_form_sheet.dart — Bottom sheet de confirmation et création de réservation
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/bien_detail.dart';
import '../../services/reservation_service.dart';

/// Affiche le récapitulatif et la confirmation de réservation.
///
/// Retourne `true` si la réservation a été créée avec succès.
Future<bool> showReservationFormSheet({
  required BuildContext context,
  required BienDetail bien,
  required DateTime dateDebut,
  required DateTime dateFin,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReservationFormSheet(
      bien:      bien,
      dateDebut: dateDebut,
      dateFin:   dateFin,
    ),
  );
  return result ?? false;
}

class ReservationFormSheet extends StatefulWidget {
  final BienDetail bien;
  final DateTime dateDebut;
  final DateTime dateFin;

  const ReservationFormSheet({
    super.key,
    required this.bien,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  State<ReservationFormSheet> createState() => _ReservationFormSheetState();
}

class _ReservationFormSheetState extends State<ReservationFormSheet> {
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  bool    _isLoading = false;
  String? _error;

  int get _nbNuits => widget.dateFin.difference(widget.dateDebut).inDays;

  double? get _estimatedCost {
    final tarif = widget.bien.tarifPourDate(widget.dateDebut);
    if (tarif == null || tarif == 0) return null;
    return tarif * _nbNuits / 7;
  }

  String _fmtDate(DateTime d) => DateFormat('d MMM yyyy', 'fr_FR').format(d);

  Future<void> _confirmer() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await ReservationService.createReservation(
        idBiens:   widget.bien.idBiens,
        dateDebut: widget.dateDebut,
        dateFin:   widget.dateFin,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = result['message'] as String? ?? 'Erreur inconnue.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cost = _estimatedCost;
    final fmt  = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Poignée ─────────────────────────────────────────────────
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
              const SizedBox(height: 20),

              // ── Titre ────────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: _accent),
                  const SizedBox(width: 10),
                  const Text(
                    'Confirmer la réservation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Récapitulatif bien ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du bien
                    Text(
                      widget.bien.nomBiens,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.bien.nomCommune != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.bien.nomCommune}${widget.bien.cpCommune != null ? ' (${widget.bien.cpCommune})' : ''}',
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ],

                    const Divider(color: Colors.white12, height: 24),

                    // Dates
                    _infoRow(
                      Icons.calendar_today,
                      'Arrivée',
                      _fmtDate(widget.dateDebut),
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.calendar_today_outlined,
                      'Départ',
                      _fmtDate(widget.dateFin),
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.nights_stay_outlined,
                      'Durée',
                      '$_nbNuits nuit${_nbNuits > 1 ? 's' : ''}',
                    ),

                    const Divider(color: Colors.white12, height: 24),

                    // Prix
                    if (widget.bien.tarifPourDate(widget.dateDebut) != null) ...[
                      _infoRow(
                        Icons.payments_outlined,
                        'Tarif / semaine',
                        fmt.format(widget.bien.tarifPourDate(widget.dateDebut)),
                      ),
                      const SizedBox(height: 8),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total estimé',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          cost != null
                              ? fmt.format(cost)
                              : 'Calculé à la confirmation',
                          style: TextStyle(
                            color: cost != null ? _accent : Colors.white54,
                            fontSize: cost != null ? 18 : 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Avertissement ────────────────────────────────────────────
              const Text(
                'En confirmant, vous acceptez les conditions de réservation HAP. '
                'Le prix final sera indiqué dans votre espace réservations.',
                style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.5),
              ),

              const SizedBox(height: 16),

              // ── Erreur ───────────────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Bouton Confirmer ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Confirmer la réservation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(
            value ?? '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}
