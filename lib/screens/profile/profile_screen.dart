/// profile_screen.dart — Écran Profil complet HAP Mobile
///
/// 3 onglets via TabBar :
///   0 → Infos personnelles
///   1 → Historique réservations
///   2 → Paramètres
library;

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_preferences_service.dart';
import 'edit_profile_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF1a1a2e);
  static const Color _accent = Color(0xFFe94560);

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bg, Color(0xFF0f1726)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: _ProfileHeader(user: user)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: _accent,
                  indicatorWeight: 2,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Infos'),
                    Tab(
                      icon: Icon(Icons.calendar_month_outlined, size: 18),
                      text: 'Réservations',
                    ),
                    Tab(icon: Icon(Icons.settings_outlined, size: 18), text: 'Paramètres'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _InfosTab(user: user),
              const _ReservationsTab(),
              const _ParametresTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User? user;

  static const Color _accent = Color(0xFFe94560);

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 360;
    final firstName = user?.prenom ?? '';
    final lastName = user?.nom ?? '';
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
    final fullName = user != null ? '$firstName $lastName'.trim() : 'Invité';
    final email = user?.email;
    final phone = user?.telephone;
    final city = user?.nomCommune;
    final cp = user?.cpCommune;

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 18,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF16213e),
              const Color(0xFF111827),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: isCompact ? 76 : 88,
              height: isCompact ? 76 : 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accent.withAlpha(220),
                    const Color(0xFFff6b81),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withAlpha(70),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: isCompact ? 12 : 14),
            Text(
              fullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 20 : 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            if (email != null)
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: isCompact ? 12 : 13),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (city != null)
                  _ProfileChip(
                    icon: Icons.location_city_outlined,
                    label: '${cp ?? ''} $city'.trim(),
                  ),
                if (phone != null)
                  _ProfileChip(
                    icon: Icons.phone_outlined,
                    label: phone,
                  ),
              ],
            ),
            if (user != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  final updated = await showEditProfileSheet(context, user!);
                  if (updated && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil mis à jour.'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier le profil'),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfosTab extends StatelessWidget {
  final dynamic user;

  const _InfosTab({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Connectez-vous pour voir vos informations.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _SectionTitle(title: 'Identité'),
        _InfoRow(icon: Icons.person_outline, label: 'Prénom', value: user.prenom as String),
        _InfoRow(icon: Icons.person_outline, label: 'Nom', value: user.nom as String),
        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email as String),
        if (user.telephone != null)
          _InfoRow(icon: Icons.phone_outlined, label: 'Téléphone', value: user.telephone as String),
        if (user.dateNaissance != null)
          _InfoRow(
            icon: Icons.cake_outlined,
            label: 'Naissance',
            value: _formatDate(user.dateNaissance as String),
          ),
        const SizedBox(height: 16),
        const _SectionTitle(title: 'Adresse'),
        if (user.rue != null)
          _InfoRow(icon: Icons.home_outlined, label: 'Rue', value: user.rue as String),
        if (user.complement != null)
          _InfoRow(
            icon: Icons.add_location_alt_outlined,
            label: 'Complément',
            value: user.complement as String,
          ),
        if (user.nomCommune != null)
          _InfoRow(
            icon: Icons.location_city_outlined,
            label: 'Commune',
            value: '${user.cpCommune ?? ''} ${user.nomCommune}'.trim(),
          ),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final parts = iso.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {}
    return iso;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFe94560),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationsTab extends StatefulWidget {
  const _ReservationsTab();

  @override
  State<_ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<_ReservationsTab>
    with AutomaticKeepAliveClientMixin {
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent = Color(0xFFe94560);

  List<Map<String, dynamic>> _reservations = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) {
        setState(() {
          _error = 'Connectez-vous pour voir vos réservations.';
          _loading = false;
        });
        return;
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.mesReservations),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          setState(() {
            _reservations = List<Map<String, dynamic>>.from(data['data'] as List<dynamic>);
            _loading = false;
          });
          return;
        }
      }

      setState(() {
        _error = 'Impossible de charger les réservations.';
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Erreur réseau.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadReservations,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Center(
                  child: Text('🏖️', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune réservation pour l\'instant.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Explorez les biens disponibles !',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      color: _accent,
      backgroundColor: _surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _reservations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _ReservationCard(reservation: _reservations[index]);
        },
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> reservation;

  static const Color _surface = Color(0xFF16213e);
  static const Color _accent = Color(0xFFe94560);

  const _ReservationCard({required this.reservation});

  Color _statutColor(String statut) {
    switch (statut) {
      case 'en_cours':
        return const Color(0xFF4CAF50);
      case 'a_venir':
        return const Color(0xFF2196F3);
      case 'termine':
        return Colors.white38;
      default:
        return Colors.white38;
    }
  }

  String _statutLabel(String statut) {
    switch (statut) {
      case 'en_cours':
        return 'En cours';
      case 'a_venir':
        return 'À venir';
      case 'termine':
        return 'Terminé';
      default:
        return statut;
    }
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bien = reservation['bien'] as Map<String, dynamic>;
    final statut = reservation['statut'] as String? ?? '';
    final photo = ApiConfig.photoUrl(bien['photo'] as String?);
    final couleur = _statutColor(statut);

    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: couleur.withAlpha(25),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  _statutLabel(statut),
                  style: TextStyle(
                    color: couleur,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '#${reservation['id_reservation']}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: photo.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photo,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _photoPh(),
                          )
                        : _photoPh(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bien['nom_biens'] as String? ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (bien['nom_commune'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '📍 ${bien['nom_commune']}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 13),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${_formatDate(reservation['date_debut'] as String)} → ${_formatDate(reservation['date_fin'] as String)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.nights_stay_outlined, color: Colors.white38, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${reservation['nb_nuits']} nuit${(reservation['nb_nuits'] as int) > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            '${(reservation['total_cost'] as num).toStringAsFixed(0)} €',
                            style: const TextStyle(
                              color: _accent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPh() {
    return Container(
      color: const Color(0xFF0f3460),
      child: const Center(child: Text('🏠', style: TextStyle(fontSize: 28))),
    );
  }
}

class _ParametresTab extends StatelessWidget {
  const _ParametresTab();

  @override
  Widget build(BuildContext context) {
    return const _ParametresTabBody();
  }
}

class _ParametresTabBody extends StatefulWidget {
  const _ParametresTabBody();

  @override
  State<_ParametresTabBody> createState() => _ParametresTabBodyState();
}

class _ParametresTabBodyState extends State<_ParametresTabBody> {
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent = Color(0xFFe94560);

  bool _loading = true;
  bool _notificationsEnabled = true;
  bool _compactLayout = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final notifications = await AppPreferencesService.getNotificationsEnabled();
    final compactLayout = await AppPreferencesService.getCompactLayout();

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notifications;
      _compactLayout = compactLayout;
      _loading = false;
    });
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await AppPreferencesService.setNotificationsEnabled(value);
  }

  Future<void> _setCompactLayout(bool value) async {
    setState(() => _compactLayout = value);
    await AppPreferencesService.setCompactLayout(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _SectionTitle(title: 'Compte'),
        _SettingsTile(
          icon: Icons.edit_outlined,
          label: 'Modifier le profil',
          color: Colors.white,
          onTap: () async {
            final user = context.read<AuthProvider>().currentUser;
            if (user == null) return;
            final updated = await showEditProfileSheet(context, user);
            if (updated && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil mis à jour.'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _SwitchSettingsTile(
          icon: Icons.notifications_none,
          label: 'Notifications',
          subtitle: 'Conserver les alertes locales sur cet appareil.',
          value: _notificationsEnabled,
          onChanged: _setNotifications,
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.notifications_active_outlined,
          label: 'Centre de notifications',
          subtitle: 'Consulter les rappels et alertes récentes.',
          color: Colors.white,
          onTap: () => context.push('/notifications'),
        ),
        const SizedBox(height: 12),
        _SwitchSettingsTile(
          icon: Icons.view_agenda_outlined,
          label: 'Affichage compact',
          subtitle: 'Réduit les espacements sur les petits écrans.',
          value: _compactLayout,
          onChanged: _setCompactLayout,
        ),

        const SizedBox(height: 20),
        const _SectionTitle(title: 'Session'),
        _SettingsTile(
          icon: Icons.logout,
          label: 'Se déconnecter',
          color: _accent,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: _surface,
                title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Voulez-vous vraiment vous déconnecter ?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Déconnecter', style: TextStyle(color: Color(0xFFe94560))),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            }
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: const Column(
            children: [
              Text(
                'HAP Mobile',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Version mobile optimisée pour la recherche, les favoris et les réservations.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _SwitchSettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFe94560),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBarPreferredHeight;

  @override
  double get maxExtent => tabBarPreferredHeight;

  double get tabBarPreferredHeight => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF16213e),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
