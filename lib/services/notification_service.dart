import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/reservation.dart';
import 'reservation_service.dart';

class NotificationService {
  static const String _cacheKey = 'app_notifications_cache';

  static Future<List<AppNotificationItem>> loadNotifications({bool refresh = true}) async {
    final stored = await _loadStoredNotifications();
    final generated = refresh ? await _generateFromReservations() : <AppNotificationItem>[];

    final byId = <String, AppNotificationItem>{
      for (final item in stored) item.id: item,
    };

    for (final item in generated) {
      byId[item.id] = byId[item.id]?.copyWith(isRead: byId[item.id]!.isRead) ?? item;
    }

    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await _saveNotifications(merged);
    return merged;
  }

  static Future<int> getUnreadCount() async {
    final items = await loadNotifications(refresh: true);
    return items.where((item) => !item.isRead).length;
  }

  static Future<void> markAsRead(String id) async {
    final items = await _loadStoredNotifications();
    final updated = [
      for (final item in items)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
    await _saveNotifications(updated);
  }

  static Future<void> markAllAsRead() async {
    final items = await _loadStoredNotifications();
    await _saveNotifications(items.map((item) => item.copyWith(isRead: true)).toList());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  static Future<List<AppNotificationItem>> _generateFromReservations() async {
    try {
      final reservations = await ReservationService.getMesReservations();
      final now = DateTime.now();
      final notifications = <AppNotificationItem>[];

      for (final reservation in reservations) {
        final start = DateTime.tryParse(reservation.dateDebut);
        final end = DateTime.tryParse(reservation.dateFin);
        if (start == null || end == null) continue;

        final daysUntilStart = start.difference(DateTime(now.year, now.month, now.day)).inDays;
        final isUpcoming = reservation.statut == StatutReservation.aVenir && daysUntilStart >= 0 && daysUntilStart <= 7;
        final isTodayOrOngoing = now.isAfter(start.subtract(const Duration(days: 1))) && now.isBefore(end.add(const Duration(days: 1)));

        if (isUpcoming) {
          notifications.add(
            AppNotificationItem(
              id: 'reservation-upcoming-${reservation.idReservation}',
              title: 'Réservation à venir',
              body: '${reservation.bien.nomBiens} démarre le ${_formatDate(start)}.',
              category: 'reservation',
              createdAt: start.subtract(const Duration(days: 1)),
              isRead: false,
            ),
          );
        }

        if (isTodayOrOngoing) {
          notifications.add(
            AppNotificationItem(
              id: 'reservation-ongoing-${reservation.idReservation}',
              title: 'Séjour en cours',
              body: '${reservation.bien.nomBiens} est en cours jusqu’au ${_formatDate(end)}.',
              category: 'reservation',
              createdAt: now.subtract(const Duration(hours: 4)),
              isRead: false,
            ),
          );
        }
      }

      if (notifications.isEmpty) {
        notifications.add(
          AppNotificationItem(
            id: 'app-no-updates',
            title: 'Aucune alerte critique',
            body: 'Vos notifications sont à jour. Revenez ici pour les rappels de réservations.',
            category: 'system',
            createdAt: now,
            isRead: false,
          ),
        );
      }

      return notifications;
    } catch (_) {
      return [
        AppNotificationItem(
          id: 'app-offline',
          title: 'Notifications indisponibles',
          body: 'Impossible de récupérer les rappels pour le moment.',
          category: 'system',
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];
    }
  }

  static Future<List<AppNotificationItem>> _loadStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => AppNotificationItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveNotifications(List<AppNotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(items.map((item) => item.toJson()).toList()));
  }

  static String _formatDate(DateTime date) {
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}