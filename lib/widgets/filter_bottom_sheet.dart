/// filter_bottom_sheet.dart — Panneau de filtres style Airbnb/Booking
///
/// S'ouvre par le bas et expose :
///   - Type de bien (chips)
///   - Prix par semaine (RangeSlider)
///   - Nombre de couchages (stepper)
///   - Animaux acceptés (switch)
///   - Superficie (RangeSlider)
///   - Note minimale (étoiles)
///   - Tri (RadioButtons)
///
/// Retourne le [FilterOptions] mis à jour via [onApply].
library;

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/filter_options.dart';

/// Ouvre le panneau de filtres et retourne les filtres sélectionnés.
///
/// Exemple d'utilisation :
/// ```dart
/// await showFilterBottomSheet(context, filters, (updated) {
///   setState(() => _filters = updated);
/// });
/// ```
Future<void> showFilterBottomSheet(
  BuildContext context,
  FilterOptions currentFilters,
  ValueChanged<FilterOptions> onApply,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FilterBottomSheet(
      initialFilters: currentFilters,
      onApply: onApply,
    ),
  );
}

/// Widget interne du panneau de filtres.
class FilterBottomSheet extends StatefulWidget {
  /// Filtres actuellement appliqués.
  final FilterOptions initialFilters;

  /// Appelé lorsque l'utilisateur appuie sur "Appliquer".
  final ValueChanged<FilterOptions> onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // ── Couleurs ──────────────────────────────────────────────────────────────
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  // ── Types de biens disponibles (sera idéalement chargé depuis l'API) ──────
  static const List<Map<String, dynamic>> _typesDesBiens = [
    {'id': 1, 'label': 'Appartement'},
    {'id': 2, 'label': 'Maison'},
    {'id': 3, 'label': 'Villa'},
    {'id': 4, 'label': 'Studio'},
    {'id': 5, 'label': 'Chalet'},
    {'id': 6, 'label': 'Bungalow'},
    {'id': 7, 'label': 'Loft'},
    {'id': 8, 'label': 'Penthouse'},
    {'id': 9, 'label': 'Cottage'},
    {'id': 10, 'label': 'Résidence de vacances'},
  ];

  // ── État local des filtres ────────────────────────────────────────────────
  late int? _typeBien;
  late RangeValues _prixRange;
  late int _nbCouchage;
  late bool _animaux;
  late RangeValues _superficieRange;
  late double? _noteMin;
  late SortOption _sort;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilters;
    _typeBien       = f.typeBien;
    _prixRange      = RangeValues(f.prixMin ?? 0, f.prixMax ?? 5000);
    _nbCouchage     = f.nbCouchageMin ?? 1;
    _animaux        = f.animaux ?? false;
    _superficieRange = RangeValues(f.superficieMin ?? 0, f.superficieMax ?? 500);
    _noteMin        = f.noteMin;
    _sort           = f.sort;
  }

  /// Nombre de filtres actifs dans l'état local courant.
  int get _activeCount {
    int count = 0;
    if (_typeBien != null) count++;
    if (_prixRange.start > 0 || _prixRange.end < 5000) count++;
    if (_nbCouchage > 1) count++;
    if (_animaux) count++;
    if (_superficieRange.start > 0 || _superficieRange.end < 500) count++;
    if (_noteMin != null) count++;
    return count;
  }

  void _reset() {
    setState(() {
      _typeBien        = null;
      _prixRange       = const RangeValues(0, 5000);
      _nbCouchage      = 1;
      _animaux         = false;
      _superficieRange = const RangeValues(0, 500);
      _noteMin         = null;
      _sort            = SortOption.noteDesc;
    });
  }

  void _apply() {
    final updated = FilterOptions(
      typeBien:      _typeBien,
      prixMin:       _prixRange.start > 0    ? _prixRange.start    : null,
      prixMax:       _prixRange.end   < 5000 ? _prixRange.end      : null,
      nbCouchageMin: _nbCouchage > 1         ? _nbCouchage         : null,
      animaux:       _animaux                ? true                : null,
      superficieMin: _superficieRange.start > 0   ? _superficieRange.start : null,
      superficieMax: _superficieRange.end   < 500 ? _superficieRange.end   : null,
      noteMin:       _noteMin,
      sort:          _sort,
      // Conserver le search et commune existants
      search:        widget.initialFilters.search,
      communeId:     widget.initialFilters.communeId,
    );
    Navigator.of(context).pop();
    widget.onApply(updated);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Handle + titre ─────────────────────────────────────────
              _buildHeader(),
              const Divider(color: Colors.white12, height: 1),

              // ── Contenu scrollable ─────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSectionTitle('Type de bien'),
                    const SizedBox(height: 8),
                    _buildTypeBienChips(),
                    const SizedBox(height: 20),

                    _buildSectionTitle(
                        'Prix par semaine  (${_prixRange.start.toInt()} € — ${_prixRange.end.toInt()} €)'),
                    _buildPrixSlider(),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Nombre de couchages'),
                    _buildCouchageStepper(),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Animaux acceptés'),
                    _buildAnimauxSwitch(),
                    const SizedBox(height: 20),

                    _buildSectionTitle(
                        'Superficie (${_superficieRange.start.toInt()} m² — ${_superficieRange.end.toInt()} m²)'),
                    _buildSuperficieSlider(),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Note minimale'),
                    _buildNoteSelector(),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Trier par'),
                    _buildSortOptions(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // ── Boutons bas ────────────────────────────────────────────
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  // ── Sections UI ───────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          // Handle de drag
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtres',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_activeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_activeCount actif${_activeCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTypeBienChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _typesDesBiens.map((type) {
          final id = type['id'] as int;
          final selected = _typeBien == id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type['label'] as String),
              selected: selected,
              onSelected: (_) {
                setState(() => _typeBien = selected ? null : id);
              },
              selectedColor: _accent,
              backgroundColor: _surface,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? _accent : Colors.white24,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrixSlider() {
    return RangeSlider(
      values: _prixRange,
      min: 0,
      max: 5000,
      divisions: 100,
      activeColor: _accent,
      inactiveColor: _surface,
      onChanged: (v) => setState(() => _prixRange = v),
    );
  }

  Widget _buildCouchageStepper() {
    return Row(
      children: [
        _stepperButton(
          icon: Icons.remove,
          onTap: () {
            if (_nbCouchage > 1) setState(() => _nbCouchage--);
          },
        ),
        const SizedBox(width: 16),
        Text(
          '$_nbCouchage',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        _stepperButton(
          icon: Icons.add,
          onTap: () {
            if (_nbCouchage < 20) setState(() => _nbCouchage++);
          },
        ),
        const SizedBox(width: 8),
        const Text(
          'personnes minimum',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }

  Widget _buildAnimauxSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Text('🐾', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              'Animaux acceptés',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        Switch(
          value: _animaux,
          onChanged: (v) => setState(() => _animaux = v),
          activeThumbColor: _accent,
        ),
      ],
    );
  }

  Widget _buildSuperficieSlider() {
    return RangeSlider(
      values: _superficieRange,
      min: 0,
      max: 500,
      divisions: 50,
      activeColor: _accent,
      inactiveColor: _surface,
      onChanged: (v) => setState(() => _superficieRange = v),
    );
  }

  Widget _buildNoteSelector() {
    return RatingBar.builder(
      initialRating: _noteMin ?? 0,
      minRating: 1,
      allowHalfRating: false,
      itemCount: 5,
      itemSize: 36,
      glow: false,
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Color(0xFFFFD700),
      ),
      onRatingUpdate: (rating) {
        setState(() {
          // Double tap sur la même note → réinitialise
          _noteMin = (_noteMin == rating) ? null : rating;
        });
      },
    );
  }

  Widget _buildSortOptions() {
    return Column(
      children: SortOption.values.map((option) {
        return RadioListTile<SortOption>(
          title: Text(
            option.label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          value: option,
          groupValue: _sort,
          onChanged: (v) => setState(() => _sort = v!),
          activeColor: _accent,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Row(
          children: [
            // Réinitialiser
            Expanded(
              child: OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Réinitialiser'),
              ),
            ),
            const SizedBox(width: 12),

            // Appliquer
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Appliquer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
