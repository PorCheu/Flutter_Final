// Statistics repository for managing habit completion and progress tracking.

import '../../models/statistics_model.dart';
import '../datasources/local_data_source.dart';

class StatisticsRepository {
  final LocalDataSource _localDataSource;

  StatisticsRepository(this._localDataSource);

  Future<List<StatisticsModel>> getAllStatistics() async {
    return await _localDataSource.loadStatistics();
  }

  Future<List<StatisticsModel>> getStatisticsForAlert(String alertId) async {
    return await _localDataSource.loadStatisticsForAlert(alertId);
  }

  Future<void> recordStatistic(StatisticsModel stat) async {
    await _localDataSource.addStatistic(stat);
  }

  Future<StatisticsModel?> getStatisticForAlertAndDate(String alertId, DateTime date) async {
    final stats = await _localDataSource.loadStatisticsForAlert(alertId);
    final dateOnly = DateTime(date.year, date.month, date.day);
    try {
      return stats.firstWhere((s) {
        final sDate = DateTime(s.date.year, s.date.month, s.date.day);
        return sDate.compareTo(dateOnly) == 0;
      });
    } catch (e) {
      return null;
    }
  }

  Future<double> getCompletionRate(String alertId) async {
    final stats = await _localDataSource.loadStatisticsForAlert(alertId);
    if (stats.isEmpty) return 0.0;
    final completed = stats.where((s) => s.completed).length;
    return (completed / stats.length) * 100;
  }

  Future<int> getCurrentStreak(String alertId) async {
    final stats = await _localDataSource.loadStatisticsForAlert(alertId);
    if (stats.isEmpty) return 0;
    // Sort by date descending to get the most recent
    stats.sort((a, b) => b.date.compareTo(a.date));
    // Return the streak of the most recent completed entry
    return stats.isNotEmpty && stats.first.completed ? stats.first.streakDays : 0;
  }

  Future<int> getTotalCompleted(String alertId) async {
    final stats = await _localDataSource.loadStatisticsForAlert(alertId);
    return stats.where((s) => s.completed).length;
  }

  Future<void> updateStatistic(StatisticsModel updated) async {
    final allStats = await _localDataSource.loadStatistics();
    final index = allStats.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      allStats[index] = updated;
      await _localDataSource.saveStatistics(allStats);
    }
  }
}
