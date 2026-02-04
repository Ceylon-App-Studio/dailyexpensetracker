import 'package:hive/hive.dart';
import '../models/expense.dart';

class ExpenseHiveService {
  static const _boxName = 'expenses';

  static Box<Expense> get _box => Hive.box<Expense>(_boxName);

  static List<Expense> loadExpenses() {
    return _box.values.toList();
  }

  /// ✅ Add single expense
  static Future<void> addExpense(Expense expense) async {
    await _box.add(expense);
  }

  /// ✅ Delete by key
  static Future<void> deleteExpense(Expense expense) async {
    final key = expense.key;
    if (key != null) {
      await _box.delete(key);
    }
  }

  /// ✅ Read all
  static List<Expense> getAll() {
    return _box.values.toList();
  }

  static Future<void> updateExpense({
    required Expense oldExpense,
    required Expense newExpense,
  }) async {
    final index = _box.values.toList().indexOf(oldExpense);
    if (index != -1) {
      await _box.putAt(index, newExpense);
    }
  }
}
