/// home_screen.dart — Écran d'accueil HAP Mobile (Phase 2)
///
/// Affiche la liste paginée des biens disponibles à la location avec :
///   - AppBar : logo HAP + prénom + icône notifications
///   - SearchBarWidget avec debounce
///   - ListView paginée (pagination infinie)
///   - Skeleton shimmer pendant le chargement
///   - Pull-to-refresh
///   - Gestion des erreurs réseau avec bouton "Réessayer"
///   - FAB pour ouvrir les filtres
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

import '../../models/bien.dart';
import '../../config/api_config.dart';
import '../../models/filter_options.dart';
import '../../providers/auth_provider.dart';
import '../../services/bien_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/bien_card.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/search_bar_widget.dart';

/// Écran d'accueil avec liste des biens et recherche/filtres.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Couleurs ──────────────────────────────────────────────────────────────
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  // ── État ──────────────────────────────────────────────────────────────────
  final List<Bien> _biens       = [];
  FilterOptions    _filters     = const FilterOptions.empty();
  int              _currentPage = 1;
  int              _totalPages  = 1;
  bool             _isLoading   = false;
  bool             _isLoadingMore = false;
  String?          _error;
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _isLoadingSuggestions = false;
  String _lastSuggestionQuery = '';
  int _unreadNotifications = 0;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUnreadNotifications();
    _loadBiens(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Chargement des biens ──────────────────────────────────────────────────

  Future<void> _loadBiens({bool reset = false}) async {
    if (_isLoading || _isLoadingMore) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _biens.clear();
        _currentPage = 1;
      });
    } else {
      if (_currentPage >= _totalPages) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await BienService.getBiens(
        filters: _filters,
        page: reset ? 1 : _currentPage + 1,
      );

      final newBiens = result['data'] as List<Bien>;
      setState(() {
        if (reset) {
          _biens.addAll(newBiens);
          _currentPage = 1;
        } else {
          _biens.addAll(newBiens);
          _currentPage++;
        }
        _totalPages = result['total_pages'] as int;
        _isLoading    = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading    = false;
        _isLoadingMore = false;
      });
    }
  }

  /// Charge plus de biens en approchant la fin de la liste.
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _currentPage < _totalPages) {
        _loadBiens();
      }
    }
  }

  // ── Gestion de la recherche ───────────────────────────────────────────────

  void _onSearch(String query) {
    setState(() {
      _filters = _filters.copyWith(
        search: query.isEmpty ? null : query,
        clearSearch: query.isEmpty,
      );
    });
    _loadSuggestions(query);
    _loadBiens(reset: true);
  }

  Future<void> _loadSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      if (!mounted) return;
      setState(() {
        _searchSuggestions = [];
        _isLoadingSuggestions = false;
        _lastSuggestionQuery = trimmed;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _lastSuggestionQuery = trimmed;
    });

    try {
      final suggestions = await BienService.searchSuggestions(trimmed);
      if (!mounted || _lastSuggestionQuery != trimmed) return;
      setState(() {
        _searchSuggestions = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (_) {
      if (!mounted || _lastSuggestionQuery != trimmed) return;
      setState(() {
        _searchSuggestions = [];
        _isLoadingSuggestions = false;
      });
    }
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final name = suggestion['nom_biens'] as String? ?? '';
    setState(() {
      _filters = _filters.copyWith(search: name, clearSearch: false);
      _searchSuggestions = [];
      _lastSuggestionQuery = name;
    });
    _loadBiens(reset: true);
  }

  // ── Gestion des filtres ───────────────────────────────────────────────────

  void _openFilters() {
    showFilterBottomSheet(context, _filters, (updated) {
      setState(() => _filters = updated);
      _loadBiens(reset: true);
    });
  }

  Future<void> _loadUnreadNotifications() async {
    final count = await NotificationService.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadNotifications = count);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(user?.prenom),
      body: RefreshIndicator(
        color: _accent,
        backgroundColor: _surface,
        onRefresh: () => _loadBiens(reset: true),
        child: Column(
          children: [
            // ── Barre de recherche ─────────────────────────────────────
            SearchBarWidget(
              initialValue: _filters.search ?? '',
              activeFiltersCount: _filters.activeCount,
              onSearch: _onSearch,
              onFilterTap: _openFilters,
            ),

            if (_filters.search != null && _filters.search!.trim().length >= 2)
              _buildSuggestionPanel(),

            // ── Contenu principal ──────────────────────────────────────
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFilters,
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        tooltip: 'Filtres',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.tune),
            if (_filters.activeCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_filters.activeCount}',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
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

  Widget _buildSuggestionPanel() {
    if (_isLoadingSuggestions && _searchSuggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
          ),
        ),
      );
    }

    if (_searchSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _searchSuggestions.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white10),
          itemBuilder: (context, index) {
            final item = _searchSuggestions[index];
            final photo = ApiConfig.photoUrl(item['photo'] as String?);
            final nom = item['nom_biens'] as String? ?? '';
            final commune = item['nom_commune'] as String?;
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: photo.isNotEmpty
                      ? Image.network(photo, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFF0f3460),
                          child: const Icon(Icons.home_outlined, color: Colors.white54, size: 18),
                        ),
                ),
              ),
              title: Text(
                nom,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: commune != null
                  ? Text(
                      commune,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: const Icon(Icons.north_west, color: Colors.white38, size: 16),
              onTap: () => _selectSuggestion(item),
            );
          },
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(String? prenom) {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'HAP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              prenom != null ? 'Bonjour, $prenom ✨' : 'HAP Mobile',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white70),
              if (_unreadNotifications > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFe94560),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Notifications',
          onPressed: () async {
            await context.push('/notifications');
            await _loadUnreadNotifications();
          },
        ),
      ],
    );
  }

  // ── Corps ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    // Chargement initial → skeletons
    if (_isLoading) return _buildSkeletons();

    // Erreur réseau
    if (_error != null && _biens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadBiens(reset: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Liste vide
    if (_biens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏠', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Aucun bien trouvé',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Essayez de modifier vos filtres.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (_filters.activeCount > 0)
              TextButton(
                onPressed: () {
                  setState(() => _filters = const FilterOptions.empty());
                  _loadBiens(reset: true);
                },
                child: const Text(
                  'Supprimer les filtres',
                  style: TextStyle(color: _accent),
                ),
              ),
          ],
        ),
      );
    }

    // Liste des biens
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: _biens.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _biens.length) {
          // Indicateur de chargement en bas de liste
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                color: _accent,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final bien = _biens[index];
        return BienCard(
          bien: bien,
          onTap: () {
            context.push('/bien/${bien.idBiens}', extra: bien);
          },
          onFavoriToggle: (isFav) async {
            // Toggle favori via API avec gestion d'erreur
            final token = context.read<AuthProvider>().token;
            if (token != null) {
              try {
                await BienService.toggleFavori(bien.idBiens, token);
              } catch (_) {
                // Revert UI state if API call fails
                if (mounted) {
                  setState(() => bien.isFavorite = !isFav);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impossible de modifier les favoris.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            }
          },
        );
      },
    );
  }

  // ── Skeletons shimmer ─────────────────────────────────────────────────────

  Widget _buildSkeletons() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      padding: const EdgeInsets.only(top: 4),
      itemBuilder: (_, _) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: _surface,
      highlightColor: const Color(0xFF1e2a4a),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Container(
                    height: 14,
                    width: 200,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  // Commune
                  Container(height: 10, width: 140, color: Colors.white),
                  const SizedBox(height: 8),
                  // Note
                  Container(height: 10, width: 100, color: Colors.white),
                  const SizedBox(height: 8),
                  // Prix
                  Container(height: 14, width: 80, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
