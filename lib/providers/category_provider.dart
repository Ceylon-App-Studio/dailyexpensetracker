import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../enums/category_type.dart';
import '../models/category.dart';
import '../services/category_hive_service.dart';
import 'expense_provider.dart';

final categoryProvider =
StateNotifierProvider<CategoryNotifier, List<Category>>(
      (ref) => CategoryNotifier(ref),
);

class CategoryNotifier extends StateNotifier<List<Category>> {
  final Ref ref;

  CategoryNotifier(this.ref)
      : super(
    _sorted(
      CategoryHiveService.loadCategories(_defaultCategories),
    ),
  );

  // =======================
  // DEFAULT CATEGORIES
  // =======================
  static final List<Category> _defaultCategories = [
    // -------- EXPENSE --------
    Category(
      name: 'Food',
      iconCode: Icons.restaurant.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Transport',
      iconCode: Icons.directions_bus.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Rent',
      iconCode: Icons.home.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Utilities',
      iconCode: Icons.lightbulb.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Health',
      iconCode: Icons.favorite.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Clothing',
      iconCode: Icons.checkroom.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Skin care',
      iconCode: Icons.spa.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Hygiene',
      iconCode: Icons.soap.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Groceries',
      iconCode: Icons.shopping_cart.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Telecom',
      iconCode: Icons.phone_android.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Credit cards',
      iconCode: Icons.credit_card.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Loan',
      iconCode: Icons.account_balance.codePoint,
      type: CategoryType.expense,
    ),
    Category(
      name: 'Miscellaneous',
      iconCode: Icons.more_horiz.codePoint,
      type: CategoryType.expense,
    ),

    // -------- INCOME --------
    Category(
      name: 'Salary',
      iconCode: Icons.payments.codePoint,
      type: CategoryType.income,
    ),
    Category(
      name: 'Bonus',
      iconCode: Icons.card_giftcard.codePoint,
      type: CategoryType.income,
    ),
    Category(
      name: 'Freelance',
      iconCode: Icons.work.codePoint,
      type: CategoryType.income,
    ),
    Category(
      name: 'Gift',
      iconCode: Icons.redeem.codePoint,
      type: CategoryType.income,
    ),
    Category(
      name: 'Social media',
      iconCode: Icons.camera_alt.codePoint,
      type: CategoryType.income,
    ),
  ];

  // =======================
  // ADD CATEGORY (FIXED)
  // =======================
  Future<bool> addCategory(String name, CategoryType type) async {
    if (_categoryExists(name, type)) return false;

    await CategoryHiveService.addCategory(
      name: name.trim(),
      iconCode: Icons.category.codePoint,
      type: type,
    );

    state = _sorted(CategoryHiveService.getAll());
    return true;
  }


  // =======================
  // EDIT CATEGORY (FIXED)
  // =======================
  Future<bool> editCategory(Category category, String newName) async {
    if (_categoryExists(
      newName,
      category.type,
      excludeKey: category.key,
    )) return false;

    final box = Hive.box<Category>('categories');
    final key = category.key;
    if (key == null) return false;

    final updatedCategory = Category(
      name: newName.trim(),
      iconCode: category.iconCode,
      type: category.type,
    );

    // ✅ overwrite same Hive record
    await box.put(key, updatedCategory);

    // ✅ refresh state (and re-sort)
    state = _sorted(CategoryHiveService.getAll());
    return true;
  }

  // =======================
  // DELETE CATEGORY (SAFE)
  // =======================
  Future<bool> deleteCategory(Category category) async {
    // 🚫 Protect miscellaneous
    if (_isMisc(category)) {
      return false;
    }

    // 🚫 Do not delete if category is in use
    final expenses = ref.read(expenseProvider);
    final usageCount =
        expenses.where((e) => e.category == category.name).length;

    if (usageCount > 0) {
      return false;
    }

    await CategoryHiveService.deleteCategory(category);

    state = _sorted(CategoryHiveService.getAll());
    return true;
  }

  // =======================
  // HELPERS
  // =======================
  bool _categoryExists(
      String name,
      CategoryType type, {
        dynamic excludeKey,
      }) {
    final normalized = name.trim().toLowerCase();

    return state.any((c) {
      if (excludeKey != null && c.key == excludeKey) return false;
      return c.type == type &&
          c.name.trim().toLowerCase() == normalized;
    });
  }

  static List<Category> _sorted(List<Category> categories) {
    final misc = categories
        .where((c) =>
    c.type == CategoryType.expense &&
        c.name.toLowerCase() == 'miscellaneous')
        .toList();

    final others = categories.where((c) {
      return !(c.type == CategoryType.expense &&
          c.name.toLowerCase() == 'miscellaneous');
    }).toList();

    others.sort((a, b) {
      if (a.type != b.type) {
        return a.type.index.compareTo(b.type.index);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return [...others, ...misc];
  }

  static bool _isMisc(Category category) {
    return category.type == CategoryType.expense &&
        category.name.toLowerCase() == 'miscellaneous';
  }
}
