// Simple notification service using flutter_local_notifications.
// Beginner-friendly: initializes plugin and provides schedule/cancel helpers.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Call this early in app startup (main)
  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      // Optional callback when user taps a notification (app in foreground/background)
      onDidReceiveNotificationResponse: (details) {
        // For beginner app: do nothing here, can be extended later
      },
    );
  }

  // Schedule a one-time notification at a given DateTime
  // id should be unique (int). We will use alert id parsed to int.
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Android details
    const androidDetails = AndroidNotificationDetails(
      'habit_alert_channel',
      'Habit Alerts',
      channelDescription: 'Channel for habit alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

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

    // Schedule using the simple schedule API (works for beginners)
    // If the scheduled date is in the past this call may immediately show the notification
    await _flutterLocalNotificationsPlugin.schedule(
      id,
      title,
      body,
      scheduledDate,
      platformDetails,
      androidAllowWhileIdle: true,
    );
  }

  static Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Schedule multiple future notifications for simple repeat support.
  // For 'Daily' we schedule the next [count] days; for 'Weekly' schedule next [count] weeks.
  static Future<void> scheduleRepeating({
    required int baseId,
    required String title,
    required String body,
    required DateTime firstDate,
    required String
    repeat, // 'Daily', 'Everyday', 'Weekly', 'Custom' or weekday names
    List<int>? weekdays,
    int offsetMinutes = 0,
    int count = 30,
  }) async {
    if (repeat == 'None') return;
    // If specific weekdays provided (custom or single weekday), schedule next [count] occurrences matching those weekdays
    if (weekdays != null && weekdays.isNotEmpty) {
      int scheduled = 0;
      int idx = 0;
      DateTime cursor = firstDate;
      while (scheduled < count) {
        if (weekdays.contains(cursor.weekday)) {
          final date = DateTime(
            cursor.year,
            cursor.month,
            cursor.day,
            firstDate.hour,
            firstDate.minute,
          );
          await scheduleNotification(
            id: baseId + idx,
            title: title,
            body: body,
            scheduledDate: date,
          );
          scheduled++;
          idx++;
        }
        cursor = cursor.add(const Duration(days: 1));
      }
    } else if (repeat == 'Daily' || repeat == 'Everyday') {
      for (int i = 0; i < count; i++) {
        final date = DateTime(
          firstDate.year,
          firstDate.month,
          firstDate.day,
          firstDate.hour,
          firstDate.minute,
        ).add(Duration(days: i));
        await scheduleNotification(
          id: baseId + i,
          title: title,
          body: body,
          scheduledDate: date,
        );
      }
    } else if (repeat == 'Weekly') {
      for (int i = 0; i < (count ~/ 7); i++) {
        final date = DateTime(
          firstDate.year,
          firstDate.month,
          firstDate.day,
          firstDate.hour,
          firstDate.minute,
        ).add(Duration(days: i * 7));
        await scheduleNotification(
          id: baseId + i,
          title: title,
          body: body,
          scheduledDate: date,
        );
      }
    }
  }

  // Cancel a range of repeating notifications created with scheduleRepeating
  static Future<void> cancelRepeating(
    int baseId,
    String repeat, {
    int count = 30,
  }) async {
    if (repeat == 'None') return;
    for (int i = 0; i < count; i++) {
      await cancel(baseId + i);
    }
  }
}
