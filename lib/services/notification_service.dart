// Enhanced notification service with proper recurring notification support
// Handles all repeat types, end conditions, and edge cases

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/alert_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Maximum notifications to schedule per alert (to avoid performance issues)
  static const int _maxNotificationsPerAlert = 100;

  /// Ensure we produce a safe int id usable by platform plugins (32-bit signed)
  static int safeIdFromString(String id) {
    final parsed = int.tryParse(id);
    final raw = parsed ?? id.hashCode;
    return raw & 0x7fffffff; // ensure non-negative 32-bit
  }

  /// Initialize notification service early in app startup
  static Future<void> init() async {
    // Initialize timezone database
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      macOS: DarwinInitializationSettings(),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap (can be extended later)
      },
    );

    // Request permissions for iOS/macOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Schedule all notifications for an alert based on its configuration
  static Future<void> scheduleAlertNotifications(AlertModel alert) async {
    final baseId = safeIdFromString(alert.id);
    
    // Calculate notification time (event time - offset)
    final notificationTime = alert.dateTime.subtract(
      Duration(minutes: alert.offsetMinutes),
    );

    // Handle one-time alerts
    if (alert.repeatType == RepeatType.none) {
      await _scheduleOneTimeNotification(
        id: baseId,
        title: 'Habit Alert',
        body: alert.note,
        scheduledDate: notificationTime,
      );
      return;
    }

    // Handle recurring alerts
    await _scheduleRecurringNotifications(
      alert: alert,
      baseId: baseId,
      startTime: notificationTime,
    );
  }

  /// Schedule a single one-time notification
  static Future<void> _scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'habit_alert_channel',
      'Habit Alerts',
      channelDescription: 'Notifications for habit reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // If scheduledDate is in the past, show immediately
    if (scheduledDate.isBefore(DateTime.now())) {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
      );
      return;
    }

    // Schedule using timezone-aware zonedSchedule
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Cancel all notifications for a specific alert
  static Future<void> cancelAlertNotifications(String alertId) async {
    final baseId = safeIdFromString(alertId);
    
    // Cancel up to max notifications (we don't know exact count)
    for (int i = 0; i < _maxNotificationsPerAlert; i++) {
      await cancel(baseId + i);
    }
  }

  /// Schedule recurring notifications based on alert configuration
  static Future<void> _scheduleRecurringNotifications({
    required AlertModel alert,
    required int baseId,
    required DateTime startTime,
  }) async {
    final occurrences = _calculateOccurrences(alert, startTime);
    
    // Limit to max notifications
    final limitedOccurrences = occurrences.take(_maxNotificationsPerAlert).toList();

    // Schedule each occurrence
    for (int i = 0; i < limitedOccurrences.length; i++) {
      await _scheduleOneTimeNotification(
        id: baseId + i,
        title: 'Habit Alert',
        body: alert.note,
        scheduledDate: limitedOccurrences[i],
      );
    }
  }

  /// Calculate all occurrence dates for a recurring alert
  static List<DateTime> _calculateOccurrences(AlertModel alert, DateTime startTime) {
    final occurrences = <DateTime>[];
    final now = DateTime.now();
    DateTime cursor = startTime;

    // Start from now if startTime is in the past
    if (cursor.isBefore(now)) {
      cursor = _getNextOccurrence(alert, now) ?? cursor;
    }

    int count = 0;
    final maxIterations = 10000; // Safety limit

    while (count < maxIterations) {
      // Check end condition
      if (!_isWithinEndCondition(alert, cursor, occurrences.length)) {
        break;
      }

      // Add this occurrence if it matches the pattern
      if (_matchesRepeatPattern(alert, cursor)) {
        occurrences.add(cursor);
        
        // Check if we've reached the occurrence limit
        if (alert.endCondition == EndCondition.afterOccurrences &&
            alert.endAfterOccurrences != null &&
            occurrences.length >= alert.endAfterOccurrences!) {
          break;
        }

        // Limit total occurrences
        if (occurrences.length >= _maxNotificationsPerAlert) {
          break;
        }
      }

      // Move cursor to next potential occurrence
      cursor = _advanceCursor(alert, cursor);
      count++;
    }

    return occurrences;
  }

  /// Check if date is within end condition
  static bool _isWithinEndCondition(AlertModel alert, DateTime date, int currentCount) {
    switch (alert.endCondition) {
      case EndCondition.never:
        return true;
      case EndCondition.onDate:
        if (alert.endDate == null) return true;
        return !date.isAfter(alert.endDate!);
      case EndCondition.afterOccurrences:
        if (alert.endAfterOccurrences == null) return true;
        return currentCount < alert.endAfterOccurrences!;
    }
  }

  /// Check if a date matches the repeat pattern
  static bool _matchesRepeatPattern(AlertModel alert, DateTime date) {
    final alertDay = DateTime(
      alert.dateTime.year,
      alert.dateTime.month,
      alert.dateTime.day,
    );
    final checkDay = DateTime(date.year, date.month, date.day);

    if (checkDay.isBefore(alertDay)) return false;

    switch (alert.repeatType) {
      case RepeatType.none:
        return checkDay == alertDay;

      case RepeatType.daily:
        final daysDiff = checkDay.difference(alertDay).inDays;
        return daysDiff >= 0 && daysDiff % alert.repeatInterval == 0;

      case RepeatType.weekly:
        if (alert.weekdays.isEmpty) return false;
        final weeksDiff = (checkDay.difference(alertDay).inDays / 7).floor();
        return weeksDiff >= 0 &&
            weeksDiff % alert.repeatInterval == 0 &&
            alert.weekdays.contains(date.weekday);

      case RepeatType.monthly:
        if (date.day != alert.dateTime.day) return false;
        final monthsDiff = _monthsDifference(alertDay, checkDay);
        return monthsDiff >= 0 && monthsDiff % alert.repeatInterval == 0;

      case RepeatType.yearly:
        if (date.month != alert.dateTime.month || date.day != alert.dateTime.day) {
          return false;
        }
        final yearsDiff = date.year - alert.dateTime.year;
        return yearsDiff >= 0 && yearsDiff % alert.repeatInterval == 0;

      case RepeatType.custom:
        if (alert.weekdays.isEmpty) return false;
        return alert.weekdays.contains(date.weekday);
    }
  }

  /// Advance cursor to next potential occurrence date
  static DateTime _advanceCursor(AlertModel alert, DateTime current) {
    switch (alert.repeatType) {
      case RepeatType.none:
        return current.add(const Duration(days: 1));

      case RepeatType.daily:
        return current.add(Duration(days: alert.repeatInterval));

      case RepeatType.weekly:
      case RepeatType.custom:
        return current.add(const Duration(days: 1));

      case RepeatType.monthly:
        return DateTime(
          current.month == 12 ? current.year + 1 : current.year,
          current.month == 12 ? 1 : current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );

      case RepeatType.yearly:
        return DateTime(
          current.year + alert.repeatInterval,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
    }
  }

  /// Get next occurrence after a given date
  static DateTime? _getNextOccurrence(AlertModel alert, DateTime after) {
    DateTime cursor = after;
    final maxDays = 400; // Look ahead limit
    
    for (int i = 0; i < maxDays; i++) {
      if (_matchesRepeatPattern(alert, cursor) && cursor.isAfter(after)) {
        return DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          alert.dateTime.hour,
          alert.dateTime.minute,
        ).subtract(Duration(minutes: alert.offsetMinutes));
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    
    return null;
  }

  /// Calculate months difference between two dates
  static int _monthsDifference(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  // Legacy methods for backward compatibility (deprecated)
  @Deprecated('Use scheduleAlertNotifications instead')
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _scheduleOneTimeNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  @Deprecated('Use scheduleAlertNotifications and cancelAlertNotifications instead')
  static Future<void> scheduleRepeating({
    required int baseId,
    required String title,
    required String body,
    required DateTime firstDate,
    required String repeat,
    List<int>? weekdays,
    int offsetMinutes = 0,
    int count = 30,
  }) async {
    // Legacy implementation - convert to new format if needed
    // This is kept for any old code that might still use it
  }

  @Deprecated('Use cancelAlertNotifications instead')
  static Future<void> cancelRepeating(
    int baseId,
    String repeat, {
    int count = 30,
  }) async {
    final target = (count <= 0) ? 30 : count;
    for (int i = 0; i < target; i++) {
      await cancel(baseId + i);
    }
  }
}
