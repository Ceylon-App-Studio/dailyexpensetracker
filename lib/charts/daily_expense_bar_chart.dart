import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/expense_provider.dart';

class DailyExpenseBarChart extends ConsumerStatefulWidget {
  final DateTime month;
  final void Function(int day) onDayTap;

  const DailyExpenseBarChart({
    super.key,
    required this.month,
    required this.onDayTap,
  });

  @override
  ConsumerState<DailyExpenseBarChart> createState() =>
      _DailyExpenseBarChartState();
}

class _DailyExpenseBarChartState extends ConsumerState<DailyExpenseBarChart> {
  int? _touchedDay;

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);

    // Aggregate per day for selected month
    final Map<int, double> totals = {};
    for (final e in expenses) {
      if (e.date.year == widget.month.year && e.date.month == widget.month.month) {
        totals[e.date.day] = (totals[e.date.day] ?? 0) + e.amount;
      }
    }

    if (totals.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No daily data')),
      );
    }

    // Determine max day for highlight
    int maxDay = totals.keys.first;
    double maxTotal = totals[maxDay] ?? 0;
    totals.forEach((day, total) {
      if (total > maxTotal) {
        maxTotal = total;
        maxDay = day;
      }
    });

    final days = totals.keys.toList()..sort();

    final groups = days.map((day) {
      final total = totals[day] ?? 0;

      final isMax = day == maxDay;
      final isTouched = day == _touchedDay;

      return BarChartGroupData(
        x: day,
        barRods: [
          BarChartRodData(
            toY: total,
            width: isTouched ? 12 : 10,
            borderRadius: BorderRadius.circular(4),
            // Highlight max day with stronger opacity
            color: isMax
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withOpacity(0.55),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: _titles(),
          barGroups: groups,
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchCallback: (event, response) {
              if (event is! FlTapUpEvent) return;
              final group = response?.spot?.touchedBarGroup;
              if (group == null) return;

              final day = group.x.toInt();
              setState(() => _touchedDay = day);
              widget.onDayTap(day);
            },
          ),
        ),
      ),
    );
  }

  FlTitlesData _titles() {
    return FlTitlesData(
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 5,
          getTitlesWidget: (value, _) => Text(
            value.toInt().toString(),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }
}
