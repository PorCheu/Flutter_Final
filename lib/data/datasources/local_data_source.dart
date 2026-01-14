// Local data source using shared_preferences for all storage operations.
// This layer handles all low-level localStorage interactions.

import 'package:shared_preferences/shared_preferences.dart';
import '../../models/alert_model.dart';
import '../../models/user_model.dart';
import '../../models/habit_category_model.dart';
import '../../models/statistics_model.dart';

class LocalDataSource {
  static const String _alertsKey = 'alerts';
  static const String _userKey = 'user';
  static const String _categoriesKey = 'categories';
  static const String _statisticsKey = 'statistics';
  static const String _initializedKey = 'initialized';

  // Get SharedPreferences instance
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // ========== Alert Operations ==========
  Future<List<AlertModel>> loadAlerts() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_alertsKey);
    if (jsonString == null) return [];
    try {
      final alerts = AlertModel.decodeList(jsonString);
      alerts.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return alerts;
    } catch (e) {
      return [];
    }
  }

  Future<void> saveAlerts(List<AlertModel> alerts) async {
    final prefs = await _getPrefs();
    final jsonString = AlertModel.encodeList(alerts);
    await prefs.setString(_alertsKey, jsonString);
  }

  Future<void> addAlert(AlertModel alert) async {
    final alerts = await loadAlerts();
    alerts.add(alert);
    await saveAlerts(alerts);
  }

  Future<void> updateAlert(AlertModel updated) async {
    final alerts = await loadAlerts();
    final index = alerts.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      alerts[index] = updated;
      await saveAlerts(alerts);
    }
  }

  Future<void> deleteAlert(String id) async {
    final alerts = await loadAlerts();
    alerts.removeWhere((a) => a.id == id);
    await saveAlerts(alerts);
  }

  Future<List<AlertModel>> loadAlertsForDate(DateTime date) async {
    final alerts = await loadAlerts();
    final filtered = alerts.where((a) {
      return a.dateTime.year == date.year &&
          a.dateTime.month == date.month &&
          a.dateTime.day == date.day;
    }).toList();
    filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return filtered;
  }

  // ========== User Operations ==========
  Future<UserModel?> loadUser() async {
    final prefs = await _getPrefs();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      return UserModel.decode(userJson);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await _getPrefs();
    await prefs.setString(_userKey, UserModel.encode(user));
  }

  // ========== Category Operations ==========
  Future<List<HabitCategoryModel>> loadCategories() async {
    final prefs = await _getPrefs();
    final categoriesJson = prefs.getString(_categoriesKey);
    if (categoriesJson == null) return [];
    try {
      return HabitCategoryModel.decodeList(categoriesJson);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCategories(List<HabitCategoryModel> categories) async {
    final prefs = await _getPrefs();
    await prefs.setString(_categoriesKey, HabitCategoryModel.encodeList(categories));
  }

  Future<void> addCategory(HabitCategoryModel category) async {
    final categories = await loadCategories();
    categories.add(category);
    await saveCategories(categories);
  }

  Future<void> deleteCategory(String id) async {
    final categories = await loadCategories();
    categories.removeWhere((c) => c.id == id);
    await saveCategories(categories);
  }

  // ========== Statistics Operations ==========
  Future<List<StatisticsModel>> loadStatistics() async {
    final prefs = await _getPrefs();
    final statsJson = prefs.getString(_statisticsKey);
    if (statsJson == null) return [];
    try {
      return StatisticsModel.decodeList(statsJson);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveStatistics(List<StatisticsModel> stats) async {
    final prefs = await _getPrefs();
    await prefs.setString(_statisticsKey, StatisticsModel.encodeList(stats));
  }

  Future<void> addStatistic(StatisticsModel stat) async {
    final stats = await loadStatistics();
    stats.add(stat);
    await saveStatistics(stats);
  }

  Future<List<StatisticsModel>> loadStatisticsForAlert(String alertId) async {
    final stats = await loadStatistics();
    return stats.where((s) => s.alertId == alertId).toList();
  }

  // ========== Initialization ==========
  Future<bool> isInitialized() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_initializedKey) ?? false;
  }

  Future<void> setInitialized(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_initializedKey, value);
  }

  // Clear all data (for reset/logout)
  Future<void> clearAllData() async {
    final prefs = await _getPrefs();
    await prefs.remove(_alertsKey);
    await prefs.remove(_userKey);
    await prefs.remove(_categoriesKey);
    await prefs.remove(_statisticsKey);
    await prefs.remove(_initializedKey);
  }
}
