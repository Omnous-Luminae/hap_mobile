/// calendrier_disponibilites.dart — Sélecteur de dates de réservation
///
/// Widget bottom-sheet (DraggableScrollableSheet) affichant un calendrier
/// TableCalendar en mode sélection de plage de dates.
/// Les dates déjà réservées sont grisées et non sélectionnables.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/bien_detail.dart';

/// Ouvre le bottom-sheet du calendrier et attend la sélection confirmée.
///
/// Retourne `null` si l'utilisateur ferme sans confirmer.
/// Retourne `(DateTime debut, DateTime fin)` si une plage est confirmée.
Future<(DateTime, DateTime)?> showCalendrierDisponibilites({
  required BuildContext context,
  required BienDetail bien,
  required List<Map<String, String>> reservedRanges,
}) {
  return showModalBottomSheet<(DateTime, DateTime)?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CalendrierDisponibilitesSheet(
      bien: bien,
      reservedRanges: reservedRanges,
    ),
  );
}

class CalendrierDisponibilitesSheet extends StatefulWidget {
  final BienDetail bien;
  final List<Map<String, String>> reservedRanges;

  const CalendrierDisponibilitesSheet({
    super.key,
    required this.bien,
    required this.reservedRanges,
  });

  @override
  State<CalendrierDisponibilitesSheet> createState() =>
      _CalendrierDisponibilitesSheetState();
}

class _CalendrierDisponibilitesSheetState
    extends State<CalendrierDisponibilitesSheet> {
  // ── Couleurs ───────────────────────────────────────────────────────────────
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  // ── État du calendrier ─────────────────────────────────────────────────────
  CalendarFormat _format        = CalendarFormat.month;
  DateTime       _focusedDay    = DateTime.now();
  DateTime?      _rangeStart;
  DateTime?      _rangeEnd;

  // Ensemble des jours bloqués (dates dans des plages réservées)
  late final Set<DateTime> _blockedDays;

  @override
  void initState() {
    super.initState();
    _blockedDays = _buildBlockedDays();
  }

  /// Construit l'ensemble de toutes les dates bloquées à partir des plages réservées.
  Set<DateTime> _buildBlockedDays() {
    final Set<DateTime> blocked = {};
    for (final range in widget.reservedRanges) {
      var current = DateTime.parse(range['debut']!);
      final end   = DateTime.parse(range['fin']!);
      while (!current.isAfter(end)) {
        blocked.add(DateTime(current.year, current.month, current.day));
        current = current.add(const Duration(days: 1));
      }
    }
    return blocked;
  }

  bool _isDayBlocked(DateTime day) {
    return _blockedDays.contains(DateTime(day.year, day.month, day.day));
  }

  bool _isDayBeforeToday(DateTime day) {
    final today = DateTime.now();
    return day.isBefore(DateTime(today.year, today.month, today.day));
  }

  bool _isSelectableDay(DateTime day) =>
      !_isDayBlocked(day) && !_isDayBeforeToday(day);

  /// Nombre de nuits entre la sélection start/end.
  int get _nbNuits =>
      (_rangeStart != null && _rangeEnd != null)
          ? _rangeEnd!.difference(_rangeStart!).inDays
          : 0;

  /// Estimation du coût total pour la plage sélectionnée.
  double? get _estimatedCost {
    if (_rangeStart == null || _rangeEnd == null) return null;
    final tarif = widget.bien.tarifPourDate(_rangeStart!);
    if (tarif == null || tarif == 0) return null;
    return (tarif * _nbNuits / 7);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Clic simple : début de sélection
    setState(() {
      _focusedDay = focusedDay;
      _rangeStart = selectedDay;
      _rangeEnd   = null;
    });
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd   = end;
    });
  }

  void _confirm() {
    if (_rangeStart != null && _rangeEnd != null && _nbNuits >= 1) {
      Navigator.of(context).pop((_rangeStart!, _rangeEnd!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize:     0.6,
      maxChildSize:     0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Poignée ──────────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ── Titre ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: _accent),
                  const SizedBox(width: 10),
                  Text(
                    'Choisissez vos dates',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
            ),

            // ── Légende ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _legendDot(Colors.white24, 'Indisponible'),
                  const SizedBox(width: 16),
                  _legendDot(_accent.withAlpha(200), 'Sélectionné'),
                  const SizedBox(width: 16),
                  _legendDot(Colors.green.shade600, 'Disponible'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Calendrier ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: Column(
                  children: [
                    TableCalendar(
                      locale: 'fr_FR',
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                      focusedDay: _focusedDay,
                      calendarFormat: _format,
                      rangeSelectionMode: RangeSelectionMode.toggledOn,
                      rangeStartDay: _rangeStart,
                      rangeEndDay:   _rangeEnd,
                      enabledDayPredicate: _isSelectableDay,
                      onDaySelected:   _onDaySelected,
                      onRangeSelected: _onRangeSelected,
                      onFormatChanged: (f) => setState(() => _format = f),
                      onPageChanged:   (f) => _focusedDay = f,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered:       true,
                        titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        leftChevronIcon:
                            Icon(Icons.chevron_left, color: Colors.white70),
                        rightChevronIcon:
                            Icon(Icons.chevron_right, color: Colors.white70),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Colors.white54, fontSize: 12),
                        weekendStyle: TextStyle(color: _accent, fontSize: 12),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle:
                            const TextStyle(color: Colors.white),
                        weekendTextStyle:
                            const TextStyle(color: Colors.white),
                        todayDecoration: BoxDecoration(
                          border: Border.all(color: _accent),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle:
                            const TextStyle(color: _accent, fontWeight: FontWeight.bold),
                        rangeStartDecoration: const BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: const BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                        withinRangeDecoration: BoxDecoration(
                          color: _accent.withAlpha(50),
                        ),
                        rangeHighlightColor: _accent.withAlpha(40),
                        disabledTextStyle:
                            const TextStyle(color: Colors.white24),
                        disabledDecoration: const BoxDecoration(
                          color: Color(0xFF0d1020),
                          shape: BoxShape.circle,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        disabledBuilder: (ctx, day, focused) {
                          final isBlocked = _isDayBlocked(day);
                          return Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isBlocked
                                    ? Colors.white12
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isBlocked
                                    ? Text(
                                        '${day.day}',
                                        style: const TextStyle(
                                          color: Colors.white24,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor: Colors.white24,
                                          fontSize: 12,
                                        ),
                                      )
                                    : Text(
                                        '${day.day}',
                                        style: const TextStyle(
                                          color: Colors.white24,
                                          fontSize: 12,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Résumé de la sélection ───────────────────────────
                    if (_rangeStart != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: _buildSummary(),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Bouton Continuer ─────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        (_rangeStart != null && _rangeEnd != null && _nbNuits >= 1)
                            ? _confirm
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      (_rangeEnd == null)
                          ? 'Sélectionnez la date de fin'
                          : 'Continuer — $_nbNuits nuit${_nbNuits > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final fmt = DateFormat('d MMM yyyy', 'fr_FR');
    final cost = _estimatedCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _summaryChip(
                Icons.flight_takeoff,
                'Arrivée',
                fmt.format(_rangeStart!),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, color: Colors.white54, size: 16),
              ),
              _summaryChip(
                Icons.flight_land,
                'Départ',
                _rangeEnd != null ? fmt.format(_rangeEnd!) : '—',
              ),
              const Spacer(),
              if (_nbNuits > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accent.withAlpha(80)),
                  ),
                  child: Text(
                    '$_nbNuits nuit${_nbNuits > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          if (cost != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimation du coût',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                Text(
                  NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 0).format(cost),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Confirmé lors de la réservation',
                style: const TextStyle(color: Colors.white30, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white38),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      );
}
