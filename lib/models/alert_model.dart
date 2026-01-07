// Simple Alert model for storing alerts locally.
// Beginner-friendly: uses simple fields and JSON (Map) conversion.

import 'dart:convert';

class AlertModel {
  String id; // unique id (we'll use DateTime millis as string)
  String note;
  DateTime dateTime;
  String
  repeat; // 'None', 'Everyday', 'Weekly', 'Custom' or single weekday names
  // If repeat is 'Custom' or specific weekdays, store selected weekdays as integers
  // Monday = 1, Sunday = 7
  List<int> weekdays;
  // Offset in minutes before the scheduled time to fire the notification
  int offsetMinutes;
  bool enabled;

  AlertModel({
    required this.id,
    required this.note,
    required this.dateTime,
    this.repeat = 'None',
    this.weekdays = const [],
    this.offsetMinutes = 0,
    this.enabled = true,
  });

  // Convert to Map for JSON encoding
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note': note,
      'dateTime': dateTime.toIso8601String(),
      'repeat': repeat,
      'weekdays': weekdays,
      'offsetMinutes': offsetMinutes,
      'enabled': enabled,
    };
  }

  // Create an instance from a Map
  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] as String,
      note: map['note'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      repeat: map['repeat'] as String? ?? 'None',
      weekdays:
          (map['weekdays'] as List<dynamic>?)?.map((e) => e as int).toList() ??
          [],
      offsetMinutes: map['offsetMinutes'] as int? ?? 0,
      enabled: map['enabled'] as bool? ?? true,
    );
  }

  // Helper to convert List<AlertModel> to/from JSON String
  static String encodeList(List<AlertModel> alerts) =>
      json.encode(alerts.map((a) => a.toMap()).toList());

  static List<AlertModel> decodeList(String alertsJson) {
    final List parsed = json.decode(alertsJson) as List;
    return parsed.map((item) => AlertModel.fromMap(item)).toList();
  }
}
