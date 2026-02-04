import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_provider.dart';

final monthlyTrendProvider = Provider<List<MonthlyTotal>>((ref) {
  final expenses = ref.watch(expenseProvider);

  final now = DateTime.now();
  final Map<String, double> totals = {};

  for (int i = 0; i < 6; i++) {
    final month = DateTime(now.year, now.month - i, 1);
    final key = _key(month);
    totals[key] = 0;
  }

  for (final e in expenses) {
    final key = _key(DateTime(e.date.year, e.date.month, 1));
    if (totals.containsKey(key)) {
      totals[key] = totals[key]! + e.amount;
    }
  }

  return totals.entries
      .map((e) => MonthlyTotal.fromKey(e.key, e.value))
      .toList()
      .reversed
      .toList();
});

String _key(DateTime d) => '${d.year}-${d.month}';

class MonthlyTotal {
  final DateTime month;
  final double total;

  MonthlyTotal(this.month, this.total);

  factory MonthlyTotal.fromKey(String key, double total) {
    final parts = key.split('-');
    return MonthlyTotal(
      DateTime(int.parse(parts[0]), int.parse(parts[1])),
      total,
    );
  }
}
