// User repository for managing user profile data operations.

import '../../models/user_model.dart';
import '../datasources/local_data_source.dart';

class UserRepository {
  final LocalDataSource _localDataSource;

  UserRepository(this._localDataSource);

  Future<UserModel?> getUser() async {
    return await _localDataSource.loadUser();
  }

  Future<void> updateUser(UserModel user) async {
    await _localDataSource.saveUser(user);
  }

  Future<void> toggleNotifications(bool enabled) async {
    final user = await _localDataSource.loadUser();
    if (user != null) {
      final updated = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt,
        notificationsEnabled: enabled,
        dailyGoal: user.dailyGoal,
      );
      await _localDataSource.saveUser(updated);
    }
  }

  Future<void> updateDailyGoal(int goal) async {
    final user = await _localDataSource.loadUser();
    if (user != null) {
      final updated = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt,
        notificationsEnabled: user.notificationsEnabled,
        dailyGoal: goal,
      );
      await _localDataSource.saveUser(updated);
    }
  }
}
