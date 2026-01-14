// Alert repository for managing alert data operations.
// Acts as a bridge between UI and data layer.

import '../../models/alert_model.dart';
import '../datasources/local_data_source.dart';

class AlertRepository {
  final LocalDataSource _localDataSource;

  AlertRepository(this._localDataSource);

  Future<List<AlertModel>> getAllAlerts() async {
    return await _localDataSource.loadAlerts();
  }

  Future<void> createAlert(AlertModel alert) async {
    await _localDataSource.addAlert(alert);
  }

  Future<void> updateAlert(AlertModel alert) async {
    await _localDataSource.updateAlert(alert);
  }

  Future<void> deleteAlert(String id) async {
    await _localDataSource.deleteAlert(id);
  }

  Future<List<AlertModel>> getAlertsForDate(DateTime date) async {
    return await _localDataSource.loadAlertsForDate(date);
  }

  Future<AlertModel?> getAlertById(String id) async {
    final alerts = await _localDataSource.loadAlerts();
    try {
      return alerts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> getAlertCount() async {
    final alerts = await _localDataSource.loadAlerts();
    return alerts.length;
  }

  Future<int> getEnabledAlertCount() async {
    final alerts = await _localDataSource.loadAlerts();
    return alerts.where((a) => a.enabled).length;
  }
}
