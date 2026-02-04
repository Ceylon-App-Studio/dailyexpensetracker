import 'package:hive/hive.dart';

import '../enums/category_type.dart';
import '../models/category.dart';

class CategoryHiveService {
  static Box<Category> get _box => Hive.box<Category>('categories');

  static List<Category> loadCategories(List<Category> defaults) {
    if (_box.isEmpty) {
      for (final c in defaults) {
        _box.add(
          Category(
            name: c.name,
            iconCode: c.iconCode,
            type: c.type,
          ),
        );
      }
    }
    return _box.values.toList();
  }

  // ✅ CREATE object here — never accept HiveObject from outside
  static Future<void> addCategory({
    required String name,
    required int iconCode,
    required CategoryType type,
  }) async {
    await _box.add(
      Category(
        name: name,
        iconCode: iconCode,
        type: type,
      ),
    );
  }

  static Future<void> deleteCategory(Category category) async {
    final key = category.key;
    if (key != null) {
      await _box.delete(key);
    }
  }

  static List<Category> getAll() {
    return _box.values.toList();
  }
}
