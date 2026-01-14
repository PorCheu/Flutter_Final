// Statistics model for tracking habit completion and progress.
import 'dart:convert';

class StatisticsModel {
  String id;
  String alertId; // Reference to the alert
  DateTime date; // Date of the statistic entry
  bool completed; // Whether the habit was completed on this date
  int streakDays; // Current streak count
  int completionRate; // Percentage (0-100)

  StatisticsModel({
    required this.id,
    required this.alertId,
    required this.date,
    required this.completed,
    this.streakDays = 0,
    this.completionRate = 0,
  });

  // Convert to Map for JSON encoding
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alertId': alertId,
      'date': date.toIso8601String(),
      'completed': completed,
      'streakDays': streakDays,
      'completionRate': completionRate,
    };
  }

  // Create an instance from a Map
  factory StatisticsModel.fromMap(Map<String, dynamic> map) {
    return StatisticsModel(
      id: map['id'] as String,
      alertId: map['alertId'] as String,
      date: DateTime.parse(map['date'] as String),
      completed: map['completed'] as bool? ?? false,
      streakDays: map['streakDays'] as int? ?? 0,
      completionRate: map['completionRate'] as int? ?? 0,
    );
  }

  // Helper to convert List<StatisticsModel> to/from JSON String
  static String encodeList(List<StatisticsModel> stats) =>
      json.encode(stats.map((s) => s.toMap()).toList());

  static List<StatisticsModel> decodeList(String statsJson) {
    final List parsed = json.decode(statsJson) as List;
    return parsed.map((item) => StatisticsModel.fromMap(item)).toList();
  }
}
