import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../models/income.dart';
import 'expense_provider.dart';
import 'income_provider.dart';

final selectedMonthProvider =
StateProvider<DateTime>((ref) => DateTime.now());

final monthlySummaryProvider = Provider<MonthlySummary>((ref) {
  final selectedMonth = ref.watch(selectedMonthProvider);

  // 👇 THIS is the key fix
  final expenses = ref.watch(expenseProvider);
  final incomes = ref.watch(incomeProvider);

  double totalIncome = 0;
  double totalExpense = 0;
  final Map<String, double> categoryTotals = {};

  /// Income
  for (final income in incomes) {
    if (income.date.year == selectedMonth.year &&
        income.date.month == selectedMonth.month) {
      totalIncome += income.amount;
    }
  }

  /// Expenses
  for (final expense in expenses) {
    if (expense.date.year == selectedMonth.year &&
        expense.date.month == selectedMonth.month) {
      totalExpense += expense.amount;
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
  }

  return MonthlySummary(
    income: totalIncome,
    expense: totalExpense,
    categoryTotals: categoryTotals,
  );
});

class MonthlySummary {
  final double income;
  final double expense;
  final Map<String, double> categoryTotals;

  MonthlySummary({
    required this.income,
    required this.expense,
    required this.categoryTotals,
  });

  double get balance => income - expense;
}
