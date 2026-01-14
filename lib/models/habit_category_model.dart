// Habit category model for organizing alerts by category/type.
import 'dart:convert';

class HabitCategoryModel {
  String id;
  String name; // e.g., 'Exercise', 'Work', 'Health', 'Learning'
  String description;
  String color; // Hex color code (e.g., '#FF5722')
  int alertCount; // Number of alerts in this category
  DateTime createdAt;

  HabitCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.alertCount = 0,
    required this.createdAt,
  });

  // Convert to Map for JSON encoding
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'alertCount': alertCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create an instance from a Map
  factory HabitCategoryModel.fromMap(Map<String, dynamic> map) {
    return HabitCategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      color: map['color'] as String,
      alertCount: map['alertCount'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // Helper to convert List<HabitCategoryModel> to/from JSON String
  static String encodeList(List<HabitCategoryModel> categories) =>
      json.encode(categories.map((c) => c.toMap()).toList());

  static List<HabitCategoryModel> decodeList(String categoriesJson) {
    final List parsed = json.decode(categoriesJson) as List;
    return parsed.map((item) => HabitCategoryModel.fromMap(item)).toList();
  }
}
