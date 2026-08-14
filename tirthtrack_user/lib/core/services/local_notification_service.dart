// ============================================================
// core/services/local_notification_service.dart
// ============================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/models/notification_models.dart';
import '../utils/logger.dart';

/// Service managing native device notifications for active alerts and broadcasts.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance =
      LocalNotificationService._();

  static const String _notifiedAlertIdsKey = 'tirthtrack_notified_alert_ids';
  static const String _notifiedPersonalIdsKey = 'tirthtrack_notified_personal_ids';

  // Android Notification Channels
  static const String _criticalChannelId = 'tirthtrack_critical_alerts';
  static const String _criticalChannelName = 'Emergency & Critical Alerts';
  static const String _criticalChannelDescription =
      'High-priority broadcast alerts, emergency warnings, and security updates.';

  static const String _generalChannelId = 'tirthtrack_general_alerts';
  static const String _generalChannelName = 'General Alerts & Announcements';
  static const String _generalChannelDescription =
      'Broadcast announcements, weather, traffic, and general mela updates.';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _notificationTapController =
      StreamController<String?>.broadcast();

  /// Stream of alert IDs or payloads from tapped notifications.
  Stream<String?> get onNotificationTapped => _notificationTapController.stream;

  bool _initialized = false;
  final Set<String> _notifiedAlertIds = <String>{};
  final Set<String> _notifiedPersonalIds = <String>{};

  /// Initialize local notifications and register handlers.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Load previously notified IDs from SharedPreferences
      await _loadNotifiedIds();

      // 2. Platform initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      // 3. Initialize plugin
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // 4. Create Android Notification Channels
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          // Critical Channel
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              _criticalChannelId,
              _criticalChannelName,
              description: _criticalChannelDescription,
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
            ),
          );

          // General Channel
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              _generalChannelId,
              _generalChannelName,
              description: _generalChannelDescription,
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
            ),
          );
        }
      }

      // 5. Check if app was launched from a notification tap (terminated state)
      final launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse != null) {
        final payload = launchDetails.notificationResponse?.payload;
        appLogger.i(
            'App launched from notification tap with payload: $payload');
        _notificationTapController.add(payload);
      }

      _initialized = true;
      appLogger.i('LocalNotificationService initialized successfully.');
    } catch (e, stack) {
      appLogger.e('LocalNotificationService initialization failed: $e\n$stack');
    }
  }

  /// Request notification permissions for Android 13+ and iOS.
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      // 1. Use permission_handler for Android 13+ POST_NOTIFICATIONS
      final status = await Permission.notification.request();
      appLogger.d('Permission.notification status: $status');

      // 2. Also invoke plugin-specific request
      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted =
            await androidPlugin?.requestNotificationsPermission() ?? false;
        appLogger.d('Android local notifications permission granted: $granted');
        return status.isGranted || granted;
      } else if (Platform.isIOS) {
        final iosPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        appLogger.d('iOS notification permission granted: $granted');
        return status.isGranted || granted;
      }
      return status.isGranted;
    } catch (e) {
      appLogger.w('Error requesting notification permissions: $e');
      return false;
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    appLogger.i('Notification tapped with payload: $payload');
    _notificationTapController.add(payload);
  }

  // ── Deduplication & Seed Tracking ───────────────────────────

  Future<void> _loadNotifiedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertList = prefs.getStringList(_notifiedAlertIdsKey) ?? [];
      _notifiedAlertIds.addAll(alertList);

      final personalList = prefs.getStringList(_notifiedPersonalIdsKey) ?? [];
      _notifiedPersonalIds.addAll(personalList);

      appLogger.d(
          'Loaded ${_notifiedAlertIds.length} alert IDs and ${_notifiedPersonalIds.length} personal notification IDs from cache.');
    } catch (e) {
      appLogger.w('Failed to load notified IDs from SharedPreferences: $e');
    }
  }

  /// Returns true if this alert has already been notified on this device.
  bool isAlertNotified(String alertId) {
    return _notifiedAlertIds.contains(alertId);
  }

  /// Returns true if this personal notification has already been notified.
  bool isPersonalNotificationNotified(String notificationId) {
    return _notifiedPersonalIds.contains(notificationId);
  }

  /// Mark an alert ID as notified both in memory and persistent storage.
  Future<void> markAlertAsNotified(String alertId) async {
    if (_notifiedAlertIds.contains(alertId)) return;
    _notifiedAlertIds.add(alertId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_notifiedAlertIdsKey, _notifiedAlertIds.toList());
    } catch (e) {
      appLogger.w('Failed to persist notified alert ID $alertId: $e');
    }
  }

  /// Mark a personal notification ID as notified.
  Future<void> markPersonalNotificationAsNotified(String notificationId) async {
    if (_notifiedPersonalIds.contains(notificationId)) return;
    _notifiedPersonalIds.add(notificationId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _notifiedPersonalIdsKey, _notifiedPersonalIds.toList());
    } catch (e) {
      appLogger.w('Failed to persist notified personal ID $notificationId: $e');
    }
  }

  // ── Show Notification For Alert ─────────────────────────────

  /// Displays a native device notification for an active, non-expired broadcast.
  /// Enforces deduplication and active/expired visibility rules.
  Future<bool> showNotificationForAlert(AlertModel alert) async {
    // 1. Strict validity and expiration check
    if (!alert.isVisibleToUser) {
      appLogger.d(
          'Skipping notification for alert "${alert.title}" (active=${alert.isActive}, expired=${alert.isExpired}).');
      return false;
    }

    // 2. Prevent duplicate notifications
    if (isAlertNotified(alert.id)) {
      return false;
    }

    try {
      final isCritical = alert.priority == AlertPriorityEnum.critical ||
          alert.priority == AlertPriorityEnum.high ||
          alert.alertType == AlertTypeEnum.emergency;

      final channelId =
          isCritical ? _criticalChannelId : _generalChannelId;
      final channelName =
          isCritical ? _criticalChannelName : _generalChannelName;
      final channelDescription = isCritical
          ? _criticalChannelDescription
          : _generalChannelDescription;

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: isCritical ? Importance.max : Importance.high,
        priority: isCritical ? Priority.max : Priority.high,
        icon: '@mipmap/ic_launcher',
        ticker: alert.title,
        styleInformation: BigTextStyleInformation(
          alert.message,
          contentTitle: alert.title,
          summaryText: alert.priority.displayLabel,
        ),
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: alert.priority.displayLabel,
        interruptionLevel:
            isCritical ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // Generate a deterministic integer ID from UUID string
      final notificationId = alert.id.hashCode & 0x7FFFFFFF;

      await _notificationsPlugin.show(
        notificationId,
        alert.title,
        alert.message,
        notificationDetails,
        payload: alert.id,
      );

      // Mark as notified in persistent storage
      await markAlertAsNotified(alert.id);
      appLogger.i(
          'Successfully displayed device notification for alert "${alert.title}" (ID: ${alert.id})');
      return true;
    } catch (e, stack) {
      appLogger.e('Failed to display alert notification: $e\n$stack');
      return false;
    }
  }

  // ── Show Notification For Personal Notification ─────────────

  /// Displays a native device notification for a personal user notification.
  Future<bool> showNotificationForPersonalNotification(
      NotificationModel notification) async {
    if (isPersonalNotificationNotified(notification.id)) {
      return false;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        _generalChannelId,
        _generalChannelName,
        channelDescription: _generalChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        ticker: 'New Notification',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final notificationId = notification.id.hashCode & 0x7FFFFFFF;

      await _notificationsPlugin.show(
        notificationId,
        notification.title,
        notification.body,
        notificationDetails,
        payload: notification.id,
      );

      await markPersonalNotificationAsNotified(notification.id);
      appLogger.i(
          'Successfully displayed device notification for personal notification "${notification.title}"');
      return true;
    } catch (e, stack) {
      appLogger.e('Failed to display personal notification: $e\n$stack');
      return false;
    }
  }

  void dispose() {
    _notificationTapController.close();
  }
}
