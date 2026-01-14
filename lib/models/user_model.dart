// User model for storing user profile and preferences.
import 'dart:convert';

class UserModel {
  String id;
  String name;
  String email;
  DateTime createdAt;
  bool notificationsEnabled;
  int dailyGoal; // Target number of alerts/habits per day

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.notificationsEnabled = true,
    this.dailyGoal = 5,
  });

  // Convert to Map for JSON encoding
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'dailyGoal': dailyGoal,
    };
  }

  // Create an instance from a Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      dailyGoal: map['dailyGoal'] as int? ?? 5,
    );
  }

  // Helper to convert to/from JSON String
  static String encode(UserModel user) => json.encode(user.toMap());
  static UserModel decode(String userJson) =>
      UserModel.fromMap(json.decode(userJson) as Map<String, dynamic>);
}
