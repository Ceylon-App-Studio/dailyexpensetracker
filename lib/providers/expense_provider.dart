import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/expense.dart';
import '../services/expense_hive_service.dart';

final expenseProvider =
StateNotifierProvider<ExpenseNotifier, List<Expense>>(
      (ref) => ExpenseNotifier(),
);

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  ExpenseNotifier() : super(ExpenseHiveService.loadExpenses());

  Future<void> addExpense(Expense expense) async {
    await ExpenseHiveService.addExpense(expense);
    state = ExpenseHiveService.getAll();
  }

  int usageCount(String categoryName) {
    return state.where((e) => e.category == categoryName).length;
  }

  Future<void> deleteExpense(Expense expense) async {
    await ExpenseHiveService.deleteExpense(expense);
    state = ExpenseHiveService.getAll();
  }

  Future<void> updateExpense({
    required Expense oldExpense,
    required Expense newExpense,
  }) async {
    await ExpenseHiveService.updateExpense(
      oldExpense: oldExpense,
      newExpense: newExpense,
    );
    state = ExpenseHiveService.getAll();
  }
}
