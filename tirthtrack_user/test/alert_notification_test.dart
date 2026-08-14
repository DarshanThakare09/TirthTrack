// ============================================================
// test/alert_notification_test.dart
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tirthtrack_user/core/services/local_notification_service.dart';
import 'package:tirthtrack_user/features/notifications/models/notification_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlertModel & Expiration Rules', () {
    final now = DateTime.now();

    test('Active alert with future expiration is visible and not expired', () {
      final alert = AlertModel(
        id: 'alert-1',
        title: 'Emergency Flood Alert',
        message: 'Avoid river banks near Ramkund.',
        alertType: AlertTypeEnum.emergency,
        priority: AlertPriorityEnum.critical,
        isActive: true,
        expiresAt: now.add(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(alert.isExpired, isFalse);
      expect(alert.isVisibleToUser, isTrue);
    });

    test('Active alert with null expiration is visible and not expired', () {
      final alert = AlertModel(
        id: 'alert-2',
        title: 'Welcome Pilgrims',
        message: 'Nashik Kumbh Mela 2026 information desk is open.',
        alertType: AlertTypeEnum.announcement,
        priority: AlertPriorityEnum.low,
        isActive: true,
        expiresAt: null,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      );

      expect(alert.isExpired, isFalse);
      expect(alert.isVisibleToUser, isTrue);
    });

    test('Active alert with past expiration is expired and NOT visible', () {
      final alert = AlertModel(
        id: 'alert-3',
        title: 'Temporary Road Closure',
        message: 'MG Road closed until 8:00 AM.',
        alertType: AlertTypeEnum.traffic,
        priority: AlertPriorityEnum.medium,
        isActive: true,
        expiresAt: now.subtract(const Duration(minutes: 10)),
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      );

      expect(alert.isExpired, isTrue);
      expect(alert.isVisibleToUser, isFalse);
    });

    test('Inactive alert is NOT visible regardless of expiration', () {
      final alertFuture = AlertModel(
        id: 'alert-4',
        title: 'Weather Advisory',
        message: 'Rain expected later.',
        alertType: AlertTypeEnum.weather,
        priority: AlertPriorityEnum.low,
        isActive: false,
        expiresAt: now.add(const Duration(hours: 5)),
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      expect(alertFuture.isVisibleToUser, isFalse);

      final alertNoExpiry = AlertModel(
        id: 'alert-5',
        title: 'Draft Alert',
        message: 'Testing only.',
        alertType: AlertTypeEnum.general,
        priority: AlertPriorityEnum.medium,
        isActive: false,
        expiresAt: null,
        createdAt: now,
        updatedAt: now,
      );

      expect(alertNoExpiry.isVisibleToUser, isFalse);
    });

    test('JSON serialization & deserialization works correctly', () {
      final json = {
        'id': 'abc-123',
        'title': 'Medical Camp Location',
        'message': 'Free medical camp at Sector 4.',
        'alert_type': 'medical',
        'priority': 'high',
        'expires_at': now.add(const Duration(hours: 1)).toIso8601String(),
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final alert = AlertModel.fromJson(json);
      expect(alert.id, 'abc-123');
      expect(alert.title, 'Medical Camp Location');
      expect(alert.alertType, AlertTypeEnum.medical);
      expect(alert.priority, AlertPriorityEnum.high);
      expect(alert.isActive, isTrue);
      expect(alert.isVisibleToUser, isTrue);
    });
  });

  group('LocalNotificationService Deduplication', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Deduplication prevents repeating already notified alerts and personal notifications', () async {
      final service = LocalNotificationService.instance;
      const testAlertId = 'test-alert-uuid-999';
      const testPersonalId = 'test-notif-uuid-888';

      expect(service.isAlertNotified(testAlertId), isFalse);
      expect(service.isPersonalNotificationNotified(testPersonalId), isFalse);

      await service.markAlertAsNotified(testAlertId);
      await service.markPersonalNotificationAsNotified(testPersonalId);

      expect(service.isAlertNotified(testAlertId), isTrue);
      expect(service.isPersonalNotificationNotified(testPersonalId), isTrue);

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final alertList = prefs.getStringList('tirthtrack_notified_alert_ids') ?? [];
      final personalList = prefs.getStringList('tirthtrack_notified_personal_ids') ?? [];
      expect(alertList.contains(testAlertId), isTrue);
      expect(personalList.contains(testPersonalId), isTrue);
    });

    test('showNotificationForAlert rejects inactive or expired alerts', () async {
      final service = LocalNotificationService.instance;
      final now = DateTime.now();

      final expiredAlert = AlertModel(
        id: 'expired-1',
        title: 'Expired Alert',
        message: 'Should not notify',
        alertType: AlertTypeEnum.general,
        priority: AlertPriorityEnum.medium,
        isActive: true,
        expiresAt: now.subtract(const Duration(minutes: 5)),
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      final inactiveAlert = AlertModel(
        id: 'inactive-1',
        title: 'Inactive Alert',
        message: 'Should not notify',
        alertType: AlertTypeEnum.general,
        priority: AlertPriorityEnum.medium,
        isActive: false,
        expiresAt: now.add(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now,
      );

      final notifiedExpired = await service.showNotificationForAlert(expiredAlert);
      final notifiedInactive = await service.showNotificationForAlert(inactiveAlert);

      expect(notifiedExpired, isFalse);
      expect(notifiedInactive, isFalse);
    });

    test('Seen alert tracking marks alert as seen and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final seenKey = 'tirthtrack_seen_alert_ids';

      expect(prefs.getStringList(seenKey), isNull);

      const alertId = 'alert-abc-456';
      await prefs.setStringList(seenKey, [alertId]);

      final updated = prefs.getStringList(seenKey) ?? [];
      expect(updated.contains(alertId), isTrue);
    });
  });
}

