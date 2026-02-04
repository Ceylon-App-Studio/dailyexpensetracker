import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

final dailyExpenseProvider = Provider<List<DailyTotal>>((ref) {
  final expenses = ref.watch(expenseProvider);

  final now = DateTime.now();
  final Map<int, double> totals = {};

  for (final e in expenses) {
    if (e.date.year == now.year && e.date.month == now.month) {
      final day = e.date.day;
      totals[day] = (totals[day] ?? 0) + e.amount;
    }
  }

  return totals.entries
      .map((e) => DailyTotal(day: e.key, total: e.value))
      .toList()
    ..sort((a, b) => a.day.compareTo(b.day));
});

class DailyTotal {
  final int day;
  final double total;

  DailyTotal({required this.day, required this.total});
}
