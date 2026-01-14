// Simple storage service using shared_preferences.
// Stores alerts, user data, categories, and statistics as JSON strings.

import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';
import '../models/user_model.dart';
import '../models/habit_category_model.dart';
import '../models/statistics_model.dart';

class StorageService {
  static const String _alertsKey = 'alerts';
  static const String _userKey = 'user';
  static const String _categoriesKey = 'categories';
  static const String _statisticsKey = 'statistics';
  static const String _initializedKey = 'initialized'; // Track if demo data was loaded

  // Initialize demo data if running on web (Chrome) for the first time
  static Future<void> initializeDemoData() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(_initializedKey) ?? false;
    
    if (!initialized) {
      // Create demo user
      final demoUser = UserModel(
        id: 'user_001',
        name: 'Demo User',
        email: 'demo@habitapp.com',
        createdAt: DateTime.now(),
        notificationsEnabled: true,
        dailyGoal: 5,
      );
      await prefs.setString(_userKey, UserModel.encode(demoUser));

      // Create demo categories
      final demoCategories = [
        HabitCategoryModel(
          id: 'cat_001',
          name: 'Exercise',
          description: 'Physical activity and fitness',
          color: '#FF5722',
          alertCount: 2,
          createdAt: DateTime.now(),
        ),
        HabitCategoryModel(
          id: 'cat_002',
          name: 'Work',
          description: 'Professional tasks and deadlines',
          color: '#2196F3',
          alertCount: 1,
          createdAt: DateTime.now(),
        ),
        HabitCategoryModel(
          id: 'cat_003',
          name: 'Health',
          description: 'Wellness and medical reminders',
          color: '#4CAF50',
          alertCount: 1,
          createdAt: DateTime.now(),
        ),
      ];
      await prefs.setString(_categoriesKey, HabitCategoryModel.encodeList(demoCategories));

      // Create demo alerts
      final now = DateTime.now();
      final demoAlerts = [
        AlertModel(
          id: '${now.millisecondsSinceEpoch}_1',
          note: 'Morning Jog',
          dateTime: DateTime(now.year, now.month, now.day, 7, 0),
          repeatType: RepeatType.daily,
          weekdays: const [],
          repeatInterval: 1,
          endCondition: EndCondition.never,
          offsetMinutes: 15,
          enabled: true,
        ),
        AlertModel(
          id: '${now.millisecondsSinceEpoch}_2',
          note: 'Yoga Session',
          dateTime: DateTime(now.year, now.month, now.day, 17, 30),
          repeatType: RepeatType.weekly,
          weekdays: const [2, 4, 6], // Tue, Thu, Sat
          repeatInterval: 1,
          endCondition: EndCondition.never,
          offsetMinutes: 10,
          enabled: true,
        ),
        AlertModel(
          id: '${now.millisecondsSinceEpoch}_3',
          note: 'Team Standup',
          dateTime: DateTime(now.year, now.month, now.day, 10, 0),
          repeatType: RepeatType.weekly,
          weekdays: const [1, 2, 3, 4, 5], // Weekdays only
          repeatInterval: 1,
          endCondition: EndCondition.never,
          offsetMinutes: 5,
          enabled: true,
        ),
        AlertModel(
          id: '${now.millisecondsSinceEpoch}_4',
          note: 'Take Vitamins',
          dateTime: DateTime(now.year, now.month, now.day, 8, 0),
          repeatType: RepeatType.daily,
          weekdays: const [],
          repeatInterval: 1,
          endCondition: EndCondition.never,
          offsetMinutes: 0,
          enabled: true,
        ),
      ];
      await prefs.setString(_alertsKey, AlertModel.encodeList(demoAlerts));

      // Create demo statistics
      final demoStats = [
        StatisticsModel(
          id: 'stat_001',
          alertId: '${now.millisecondsSinceEpoch}_1',
          date: now.subtract(const Duration(days: 1)),
          completed: true,
          streakDays: 5,
          completionRate: 100,
        ),
        StatisticsModel(
          id: 'stat_002',
          alertId: '${now.millisecondsSinceEpoch}_1',
          date: now,
          completed: true,
          streakDays: 6,
          completionRate: 100,
        ),
        StatisticsModel(
          id: 'stat_003',
          alertId: '${now.millisecondsSinceEpoch}_3',
          date: now,
          completed: false,
          streakDays: 3,
          completionRate: 75,
        ),
      ];
      await prefs.setString(_statisticsKey, StatisticsModel.encodeList(demoStats));

      // Mark as initialized
      await prefs.setBool(_initializedKey, true);
    }
  }


  // Save the whole list of alerts (overwrites existing list)
  static Future<void> saveAlerts(List<AlertModel> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = AlertModel.encodeList(alerts);
    await prefs.setString(_alertsKey, jsonString);
  }

  // Load alerts list; returns empty list if none saved
  static Future<List<AlertModel>> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_alertsKey);
    if (jsonString == null) return [];
    try {
      final alerts = AlertModel.decodeList(jsonString);
      // Sort alerts by scheduled date/time ascending so the earliest upcoming alert is first
      alerts.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return alerts;
    } catch (e) {
      // If decode fails, return empty list
      return [];
    }
  }

  // Add a single alert to the stored list
  static Future<void> addAlert(AlertModel alert) async {
    final alerts = await loadAlerts();
    alerts.add(alert);
    await saveAlerts(alerts);
  }

  // Update an existing alert by id
  static Future<void> updateAlert(AlertModel updated) async {
    final alerts = await loadAlerts();
    final index = alerts.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      alerts[index] = updated;
      await saveAlerts(alerts);
    }
  }

  // Delete an alert by id
  static Future<void> deleteAlert(String id) async {
    final alerts = await loadAlerts();
    alerts.removeWhere((a) => a.id == id);
    await saveAlerts(alerts);
  }

  // Get alerts for a specific date (year-month-day)
  static Future<List<AlertModel>> alertsForDate(DateTime date) async {
    final alerts = await loadAlerts();
    final filtered = alerts.where((a) {
      return a.dateTime.year == date.year &&
          a.dateTime.month == date.month &&
          a.dateTime.day == date.day;
    }).toList();
    // Ensure the results are ordered by time ascending
    filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return filtered;
  }

  // User management methods
  static Future<UserModel?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      return UserModel.decode(userJson);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, UserModel.encode(user));
  }

  // Category management methods
  static Future<List<HabitCategoryModel>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString(_categoriesKey);
    if (categoriesJson == null) return [];
    try {
      return HabitCategoryModel.decodeList(categoriesJson);
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveCategories(List<HabitCategoryModel> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoriesKey, HabitCategoryModel.encodeList(categories));
  }

  static Future<void> addCategory(HabitCategoryModel category) async {
    final categories = await loadCategories();
    categories.add(category);
    await saveCategories(categories);
  }

  // Statistics management methods
  static Future<List<StatisticsModel>> loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_statisticsKey);
    if (statsJson == null) return [];
    try {
      return StatisticsModel.decodeList(statsJson);
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveStatistics(List<StatisticsModel> stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statisticsKey, StatisticsModel.encodeList(stats));
  }

  static Future<void> addStatistic(StatisticsModel stat) async {
    final stats = await loadStatistics();
    stats.add(stat);
    await saveStatistics(stats);
  }

  // Get statistics for a specific alert
  static Future<List<StatisticsModel>> getStatisticsForAlert(String alertId) async {
    final stats = await loadStatistics();
    return stats.where((s) => s.alertId == alertId).toList();
  }
}
