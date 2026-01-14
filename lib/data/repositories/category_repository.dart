// Category repository for managing habit category data operations.

import '../../models/habit_category_model.dart';
import '../datasources/local_data_source.dart';

class CategoryRepository {
  final LocalDataSource _localDataSource;

  CategoryRepository(this._localDataSource);

  Future<List<HabitCategoryModel>> getAllCategories() async {
    return await _localDataSource.loadCategories();
  }

  Future<void> createCategory(HabitCategoryModel category) async {
    await _localDataSource.addCategory(category);
  }

  Future<void> updateCategory(HabitCategoryModel category) async {
    final categories = await _localDataSource.loadCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = category;
      await _localDataSource.saveCategories(categories);
    }
  }

  Future<void> deleteCategory(String id) async {
    await _localDataSource.deleteCategory(id);
  }

  Future<HabitCategoryModel?> getCategoryById(String id) async {
    final categories = await _localDataSource.loadCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> getCategoryCount() async {
    final categories = await _localDataSource.loadCategories();
    return categories.length;
  }

  Future<void> incrementAlertCount(String categoryId) async {
    final categories = await _localDataSource.loadCategories();
    final index = categories.indexWhere((c) => c.id == categoryId);
    if (index != -1) {
      categories[index].alertCount++;
      await _localDataSource.saveCategories(categories);
    }
  }

  Future<void> decrementAlertCount(String categoryId) async {
    final categories = await _localDataSource.loadCategories();
    final index = categories.indexWhere((c) => c.id == categoryId);
    if (index != -1 && categories[index].alertCount > 0) {
      categories[index].alertCount--;
      await _localDataSource.saveCategories(categories);
    }
  }
}
