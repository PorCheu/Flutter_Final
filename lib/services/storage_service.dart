// Simple storage service using shared_preferences.
// Stores a list of alerts as a JSON string under the key 'alerts'.

import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';

class StorageService {
  static const String _alertsKey = 'alerts';

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
}
