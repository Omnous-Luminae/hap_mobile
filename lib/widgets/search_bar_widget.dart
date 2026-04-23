/// search_bar_widget.dart — Barre de recherche HAP Mobile
///
/// Champ de texte avec :
///   - Icône loupe
///   - Bouton filtres avec badge rouge si filtres actifs
///   - Debounce 500 ms pour limiter les appels API
///   - Style HAP (fond sombre, border radius 12)
library;

import 'dart:async';

import 'package:flutter/material.dart';

/// Barre de recherche avec debounce et indicateur de filtres actifs.
class SearchBarWidget extends StatefulWidget {
  /// Valeur initiale du champ texte.
  final String initialValue;

  /// Nombre de filtres actifs (affiche un badge rouge si > 0).
  final int activeFiltersCount;

  /// Appelé après le debounce avec le texte saisi.
  final ValueChanged<String> onSearch;

  /// Appelé lors du tap sur le bouton filtres.
  final VoidCallback onFilterTap;

  const SearchBarWidget({
    super.key,
    this.initialValue = '',
    this.activeFiltersCount = 0,
    required this.onSearch,
    required this.onFilterTap,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  // ── Couleurs ──────────────────────────────────────────────────────────────
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  late final TextEditingController _ctrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    // Update clear button visibility as user types
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(value.trim());
    });
  }

  void _clearSearch() {
    _ctrl.clear();
    _debounce?.cancel();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _surface,
                    const Color(0xFF101828),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: _ctrl,
                onChanged: _onTextChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher un bien, une ville…',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white38,
                    size: 20,
                  ),
                  suffixIcon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _ctrl.text.isNotEmpty
                        ? IconButton(
                            key: const ValueKey('clear-search'),
                            icon: const Icon(Icons.close,
                                color: Colors.white54, size: 18),
                            onPressed: _clearSearch,
                          )
                        : const SizedBox.shrink(key: ValueKey('empty-search')),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.onFilterTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: widget.activeFiltersCount > 0
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_accent, Color(0xFFff6b81)],
                          )
                        : null,
                    color: widget.activeFiltersCount > 0 ? null : _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.tune,
                    color: widget.activeFiltersCount > 0
                        ? Colors.white
                        : Colors.white70,
                    size: 22,
                  ),
                ),
                if (widget.activeFiltersCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.activeFiltersCount}',
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
