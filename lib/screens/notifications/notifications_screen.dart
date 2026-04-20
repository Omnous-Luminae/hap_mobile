import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_notification.dart';
import '../../services/app_preferences_service.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _bg = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent = Color(0xFFe94560);

  late Future<List<AppNotificationItem>> _future;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _reload();
    _loadEnabled();
  }

  Future<void> _loadEnabled() async {
    final enabled = await AppPreferencesService.getNotificationsEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
  }

  void _reload() {
    _future = NotificationService.loadNotifications(refresh: true);
  }

  Future<void> _markAll() async {
    await NotificationService.markAllAsRead();
    if (!mounted) return;
    setState(_reload);
  }

  Future<void> _toggleEnabled(bool value) async {
    setState(() => _enabled = value);
    await AppPreferencesService.setNotificationsEnabled(value);
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'reservation':
        return Icons.calendar_month;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
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
          title: const Text('Notifications'),
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all_outlined),
              tooltip: 'Tout marquer comme lu',
              onPressed: _markAll,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualiser',
              onPressed: () => setState(_reload),
            ),
          ],
        ),
        body: FutureBuilder<List<AppNotificationItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _accent));
            }

            final items = snapshot.data ?? const <AppNotificationItem>[];
            return RefreshIndicator(
              color: _accent,
              onRefresh: () async {
                setState(_reload);
                await _future;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined, color: Colors.white70),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Rappels de réservations et alertes système générés localement.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        Switch(value: _enabled, onChanged: _toggleEnabled, activeColor: _accent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    _EmptyState(onBack: () => context.pop())
                  else
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _NotificationCard(
                            item: item,
                            icon: _iconFor(item.category),
                            onTap: () async {
                              await NotificationService.markAsRead(item.id);
                              if (!mounted) return;
                              setState(_reload);
                            },
                          ),
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationItem item;
  final IconData icon;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: item.isRead ? Colors.white10 : const Color(0xFFe94560).withAlpha(120)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: item.isRead ? Colors.white54 : const Color(0xFFe94560)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFe94560),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBack;

  const _EmptyState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
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
              child: const Icon(Icons.notifications_none, color: Colors.white54, size: 42),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune notification',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les rappels de réservation et messages système apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onBack,
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}