// Data initialization service for seeding demo data on first run.
// This manages the initialization workflow across all repositories.

import '../datasources/local_data_source.dart';
import '../repositories/alert_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/statistics_repository.dart';
import '../../models/user_model.dart';
import '../../models/habit_category_model.dart';
import '../../models/alert_model.dart';
import '../../models/statistics_model.dart';

class DataInitializationService {
  final LocalDataSource _localDataSource;
  late AlertRepository _alertRepository;
  late UserRepository _userRepository;
  late CategoryRepository _categoryRepository;
  late StatisticsRepository _statisticsRepository;

  DataInitializationService(this._localDataSource) {
    _alertRepository = AlertRepository(_localDataSource);
    _userRepository = UserRepository(_localDataSource);
    _categoryRepository = CategoryRepository(_localDataSource);
    _statisticsRepository = StatisticsRepository(_localDataSource);
  }

  Future<void> initialize() async {
    final isInitialized = await _localDataSource.isInitialized();
    
    if (!isInitialized) {
      await _seedDemoData();
      await _localDataSource.setInitialized(true);
    }
  }

  Future<void> _seedDemoData() async {
    // Seed user
    final demoUser = UserModel(
      id: 'user_001',
      name: 'Demo User',
      email: 'demo@habitapp.com',
      createdAt: DateTime.now(),
      notificationsEnabled: true,
      dailyGoal: 5,
    );
    await _userRepository.updateUser(demoUser);

    // Seed categories
    final exerciseCategory = HabitCategoryModel(
      id: 'cat_001',
      name: 'Exercise',
      description: 'Physical activity and fitness',
      color: '#FF5722',
      alertCount: 2,
      createdAt: DateTime.now(),
    );

    final workCategory = HabitCategoryModel(
      id: 'cat_002',
      name: 'Work',
      description: 'Professional tasks and deadlines',
      color: '#2196F3',
      alertCount: 1,
      createdAt: DateTime.now(),
    );

    final healthCategory = HabitCategoryModel(
      id: 'cat_003',
      name: 'Health',
      description: 'Wellness and medical reminders',
      color: '#4CAF50',
      alertCount: 1,
      createdAt: DateTime.now(),
    );

    await _categoryRepository.createCategory(exerciseCategory);
    await _categoryRepository.createCategory(workCategory);
    await _categoryRepository.createCategory(healthCategory);

    // Seed alerts
    final now = DateTime.now();
    final alert1 = AlertModel(
      id: '${now.millisecondsSinceEpoch}_1',
      note: 'Morning Jog',
      dateTime: DateTime(now.year, now.month, now.day, 7, 0),
      repeatType: RepeatType.daily,
      weekdays: const [],
      repeatInterval: 1,
      endCondition: EndCondition.never,
      offsetMinutes: 15,
      enabled: true,
    );

    final alert2 = AlertModel(
      id: '${now.millisecondsSinceEpoch}_2',
      note: 'Yoga Session',
      dateTime: DateTime(now.year, now.month, now.day, 17, 30),
      repeatType: RepeatType.weekly,
      weekdays: const [2, 4, 6],
      repeatInterval: 1,
      endCondition: EndCondition.never,
      offsetMinutes: 10,
      enabled: true,
    );

    final alert3 = AlertModel(
      id: '${now.millisecondsSinceEpoch}_3',
      note: 'Team Standup',
      dateTime: DateTime(now.year, now.month, now.day, 10, 0),
      repeatType: RepeatType.weekly,
      weekdays: const [1, 2, 3, 4, 5],
      repeatInterval: 1,
      endCondition: EndCondition.never,
      offsetMinutes: 5,
      enabled: true,
    );

    final alert4 = AlertModel(
      id: '${now.millisecondsSinceEpoch}_4',
      note: 'Take Vitamins',
      dateTime: DateTime(now.year, now.month, now.day, 8, 0),
      repeatType: RepeatType.daily,
      weekdays: const [],
      repeatInterval: 1,
      endCondition: EndCondition.never,
      offsetMinutes: 0,
      enabled: true,
    );

    await _alertRepository.createAlert(alert1);
    await _alertRepository.createAlert(alert2);
    await _alertRepository.createAlert(alert3);
    await _alertRepository.createAlert(alert4);

    // Seed statistics
    final stat1 = StatisticsModel(
      id: 'stat_001',
      alertId: '${now.millisecondsSinceEpoch}_1',
      date: now.subtract(const Duration(days: 1)),
      completed: true,
      streakDays: 5,
      completionRate: 100,
    );

    final stat2 = StatisticsModel(
      id: 'stat_002',
      alertId: '${now.millisecondsSinceEpoch}_1',
      date: now,
      completed: true,
      streakDays: 6,
      completionRate: 100,
    );

    final stat3 = StatisticsModel(
      id: 'stat_003',
      alertId: '${now.millisecondsSinceEpoch}_3',
      date: now,
      completed: false,
      streakDays: 3,
      completionRate: 75,
    );

    await _statisticsRepository.recordStatistic(stat1);
    await _statisticsRepository.recordStatistic(stat2);
    await _statisticsRepository.recordStatistic(stat3);
  }

  Future<void> resetAllData() async {
    await _localDataSource.clearAllData();
    await initialize();
  }
}
