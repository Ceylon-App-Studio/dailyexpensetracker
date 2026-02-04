import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../charts/daily_expense_bar_chart.dart';
import '../charts/monthly_trend_chart.dart';
import '../models/app_currency.dart';
import '../providers/currency_provider.dart';
import '../providers/summary_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/subscription_provider.dart';
import 'subscription_screen.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

Future<pw.ImageProvider> loadPdfLogo() async {
  final data = await rootBundle.load('assets/logo.png');
  return pw.MemoryImage(data.buffer.asUint8List());
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  int? _touchedIndex;
  bool _isBottomSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final isPremium = ref.watch(subscriptionUiProvider);

    final isCurrentMonth =
        DateTime.now().year == selectedMonth.year &&
            DateTime.now().month == selectedMonth.month;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareSummaryPdf(),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _saveSummaryPdf(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _monthNavigator(theme, selectedMonth, isCurrentMonth),
          const SizedBox(height: 16),
          _summaryCard(summary),
          const SizedBox(height: 24),
          _expensePie(summary, selectedMonth),
          const SizedBox(height: 24),
          _premiumWrapper(
            isPremium: isPremium.isPremium,
            title: 'Spending Trend (Last 6 Months)',
            subtitle: 'Understand how your spending evolves',
            child: _monthlyTrendSection(),
            onUpgrade: _goPremium,
          ),
          const SizedBox(height: 24),
          _premiumWrapper(
            isPremium: isPremium.isPremium,
            title: 'Daily Expenses',
            subtitle: 'See your spending day by day',
            child: _dailyExpenseSection(selectedMonth),
            onUpgrade: _goPremium,
          ),
        ],
      ),
    );
  }

  // ───────────────── Month Navigation ─────────────────

  Widget _monthNavigator(
      ThemeData theme, DateTime selectedMonth, bool isCurrentMonth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(selectedMonth.year, selectedMonth.month - 1);
          },
        ),
        Column(
          children: [
            Text(DateFormat.yMMMM().format(selectedMonth),
                style: theme.textTheme.titleLarge),
            if (!isCurrentMonth)
              TextButton(
                onPressed: () {
                  ref.read(selectedMonthProvider.notifier).state = DateTime.now();
                },
                child: const Text('Back to current'),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isCurrentMonth
              ? null
              : () {
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(selectedMonth.year, selectedMonth.month + 1);
          },
        ),
      ],
    );
  }

  // ───────────────── Summary Card ─────────────────

  Widget _summaryCard(summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryAmount(label: 'Income', amount: summary.income, color: Colors.green),
            _SummaryAmount(label: 'Expense', amount: summary.expense, color: Colors.red),
            _SummaryAmount(
              label: 'Balance',
              amount: summary.balance,
              color: summary.balance >= 0 ? Colors.blue : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── Expense Pie ─────────────────

  Widget _expensePie(summary, DateTime month) {
    if (summary.categoryTotals.isEmpty) {
      return const Center(child: Text('No expenses this month'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Expense Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      // ✅ Only respond when user finishes tap
                      if (event is! FlTapUpEvent) return;

                      if (_isBottomSheetOpen) return;

                      if (response == null || response.touchedSection == null) return;

                      final index =
                          response.touchedSection!.touchedSectionIndex;

                      if (index < 0 ||
                          index >= summary.categoryTotals.length) return;

                      setState(() => _touchedIndex = index);

                      final category =
                      summary.categoryTotals.keys.elementAt(index);

                      _isBottomSheetOpen = true;

                      _showCategoryTransactions(
                        context,
                        category,
                        month,
                      ).whenComplete(() {
                        _isBottomSheetOpen = false;
                        if (mounted) {
                          setState(() => _touchedIndex = null);
                        }
                      });
                    },
                  ),



                  sections: List<PieChartSectionData>.generate(
                    summary.categoryTotals.length,
                        (index) {
                      final entry = summary.categoryTotals.entries.elementAt(index);

                      final percent = (entry.value /
                          (summary.expense == 0 ? 1 : summary.expense)) *
                          100;

                      return PieChartSectionData(
                        value: entry.value,
                        radius: _touchedIndex == index ? 95 : 80,
                        color: _categoryColor(entry.key),
                        title: '${percent.toStringAsFixed(1)}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: summary.categoryTotals.entries
                  .map<Widget>((entry) {
                return _LegendItem(
                  color: _categoryColor(entry.key),
                  label: entry.key,
                  amount: entry.value,
                );
              })
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── Premium Monthly Trend ─────────────────

  Widget _monthlyTrendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MonthlyTrendChart(),
        const SizedBox(height: 12),
        _premiumActions(
          onSave: _saveTrendPdf,
          onShare: _shareTrendPdf,
        ),
      ],
    );
  }

  // ───────────────── Premium Daily Expense ─────────────────

  Widget _dailyExpenseSection(DateTime month) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _highestSpendingDay(month),
        const Divider(),
        DailyExpenseBarChart(
          month: month,
          onDayTap: _showDayExpenses,
        ),
        const SizedBox(height: 12),
        _premiumActions(
          onSave: () => _saveDailyPdf(month),
          onShare: () => _shareDailyPdf(month),
        ),
      ],
    );
  }

  // ───────────────── Premium Wrapper ─────────────────

  Widget _premiumWrapper({
    required bool isPremium,
    required String title,
    required String subtitle,
    required Widget child,
    required VoidCallback onUpgrade,
  }) {
    return Card(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
          if (!isPremium)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: onUpgrade,
                        icon: const Icon(Icons.lock),
                        label: const Text('Unlock Premium'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────── Helpers ─────────────────

  Widget _premiumActions({
    required VoidCallback onSave,
    required VoidCallback onShare,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(icon: const Icon(Icons.share), onPressed: onShare),
        IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: onSave),
      ],
    );
  }

  void _goPremium() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  // ───────────────── PDF EXPORTS ─────────────────

  Future<void> _saveSummaryPdf() async {
    final logo = await loadPdfLogo();
    final pdf = _buildSummaryPdf(logo);
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  Future<void> _shareSummaryPdf() async {
    final logo = await loadPdfLogo();
    final pdf = _buildSummaryPdf(logo);
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'summary.pdf');
  }

  Future<void> _saveTrendPdf() async {
    final logo = await loadPdfLogo();
    final pdf = _buildTrendPdf(logo);
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  Future<void> _shareTrendPdf() async {
    final logo = await loadPdfLogo();
    final pdf = _buildTrendPdf(logo);
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'trend.pdf');
  }

  Future<void> _saveDailyPdf(DateTime month) async {
    final logo = await loadPdfLogo();
    final pdf = _buildDailyPdf(month, logo);
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  Future<void> _shareDailyPdf(DateTime month) async {
    final logo = await loadPdfLogo();
    final pdf = _buildDailyPdf(month, logo);
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'daily.pdf');
  }

  // ───────────────── PDF BUILDERS ─────────────────

  pw.Document _buildSummaryPdf(pw.ImageProvider logo) {
    final summary = ref.read(monthlySummaryProvider);
    final month = ref.read(selectedMonthProvider);
    final currency = ref.read(currencyProvider);

    final doc = pw.Document();

    return doc
      ..addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(
            margin: pw.EdgeInsets.all(24),
          ),
          header: (_) => pdfHeader(
            logo: logo,
            title: kAppName,
            subtitle: DateFormat.yMMMM().format(month),
          ),
          build: (_) => [
            /// Totals
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                _tableRow('Income', formatMoney(summary.income, currency.currency)),
                _tableRow('Expense', formatMoney(summary.expense, currency.currency)),
                _tableRow('Balance', formatMoney(summary.balance, currency.currency)),
              ],
            ),

            pw.SizedBox(height: 16),

            pw.Text(
              'Summary Expense Breakdown',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.symmetric(
                inside: pw.BorderSide(color: PdfColors.grey300),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: summary.categoryTotals.entries.map((e) {
                return _tableRow(
                  e.key,
                  formatMoney(e.value, currency.currency),
                );
              }).toList(),
            ),
          ],
        ),
      );
  }

  pw.Document _buildTrendPdf(pw.ImageProvider logo) {
    final expenses = ref.read(expenseProvider);
    final currency = ref.read(currencyProvider);
    final selectedMonth = ref.read(selectedMonthProvider);

    final grouped =
    _groupExpensesByMonthAndCategory(expenses, selectedMonth);

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(24),
        ),

        /// 🔷 HEADER
        header: (_) => pdfHeader(
          logo: logo,
          title: 'Daily Expense Tracker',
          subtitle: 'Monthly Expense Trend (Last 6 Months)',
        ),

        build: (_) => [
          pw.SizedBox(height: 12),

          pw.Text(
            'Monthly Expense Breakdown',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 12),

          ...grouped.entries.map((monthEntry) {
            final month = monthEntry.key;
            final categories = monthEntry.value;

            if (categories.isEmpty) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Text(
                  '${DateFormat.yMMMM().format(month)} — No expenses',
                  style: pw.TextStyle(color: PdfColors.grey),
                ),
              );
            }

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  /// Month title
                  pw.Text(
                    DateFormat.yMMMM().format(month),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),

                  pw.SizedBox(height: 6),

                  /// Category table
                  pw.Table(
                    border: pw.TableBorder.symmetric(
                      inside: pw.BorderSide(color: PdfColors.grey300),
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(2),
                    },
                    children: categories.entries.map((cat) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(cat.key),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              formatMoney(cat.value, currency.currency),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    return doc;
  }

  pw.Document _buildDailyPdf(DateTime month, pw.ImageProvider logo) {
    final expenses = ref.read(expenseProvider);
    final currency = ref.read(currencyProvider);

    final doc = pw.Document();

    final filtered = expenses.where((e) =>
    e.date.year == month.year && e.date.month == month.month);

    final Map<int, Map<String, double>> byDay = {};

    for (final e in filtered) {
      byDay.putIfAbsent(e.date.day, () => {});
      byDay[e.date.day]![e.category] =
          (byDay[e.date.day]![e.category] ?? 0) + e.amount;
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(24),
        ),
        header: (_) => pdfHeader(
          logo: logo,
          title: kAppName,
          subtitle: 'Daily Expenses – ${DateFormat.yMMMM().format(month)}',
        ),
        build: (_) => [
          ...byDay.entries.map((dayEntry) {
            final date = DateTime(month.year, month.month, dayEntry.key);
            final categories = dayEntry.value;

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    DateFormat.yMMMd().format(date),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: kBrandColor,
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  pw.Table(
                    border: pw.TableBorder.symmetric(
                      inside: pw.BorderSide(color: PdfColors.grey300),
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(2),
                    },
                    children: categories.entries.map((cat) {
                      return _tableRow(
                        cat.key,
                        formatMoney(cat.value, currency.currency),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    return doc;
  }

  static const PdfColor kBrandColor = PdfColor.fromInt(0xFF006D6F);
  static const String kAppName = 'Daily Expense Tracker';

  pw.Widget pdfHeader({
    required pw.ImageProvider logo,
    required String title,
    String? subtitle,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: kBrandColor,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Image(logo, width: 36, height: 36),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (subtitle != null)
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────── Bottom Sheets ─────────────────

  void _showDayExpenses(int day) {
    final selectedMonth = ref.read(selectedMonthProvider);
    final currency = ref.read(currencyProvider);

    final expenses = ref.read(expenseProvider).where((e) {
      return e.date.year == selectedMonth.year &&
          e.date.month == selectedMonth.month &&
          e.date.day == day;
    }).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: expenses.isEmpty
            ? const Center(child: Text('No expenses for this day'))
            : ListView.separated(
          itemCount: expenses.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final e = expenses[i];
            return ListTile(
              title: Text(e.note.isEmpty ? 'Expense' : e.note),
              subtitle: Text(DateFormat.yMMMd().format(e.date)),
              trailing: Text(
                NumberFormat.currency(
                  symbol: currency.currency.symbol,
                ).format(e.amount),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showCategoryTransactions(
      BuildContext context,
      String category,
      DateTime month,
      ) async {
    final expenses = ref.read(expenseProvider).where((e) {
      return e.category == category &&
          e.date.year == month.year &&
          e.date.month == month.month;
    }).toList();

    final currency = ref.read(currencyProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: expenses.isEmpty
            ? const Center(child: Text('No expenses'))
            : ListView.separated(
          itemCount: expenses.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final e = expenses[i];
            return ListTile(
              title: Text(e.note.isEmpty ? 'Expense' : e.note),
              subtitle: Text(DateFormat.yMMMd().format(e.date)),
              trailing: Text(
                NumberFormat.currency(
                  symbol: currency.currency.symbol,
                ).format(e.amount),
              ),
            );
          },
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _touchedIndex = null);
    });
  }


  Widget _highestSpendingDay(DateTime month) => const SizedBox.shrink();
}

// ───────────────── Shared Widgets ─────────────────

class _SummaryAmount extends ConsumerWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryAmount({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);

    return Column(
      children: [
        Text(label),
        Text(
          NumberFormat.currency(symbol: currency.currency.symbol).format(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

Color _categoryColor(String category) {
  final colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];
  return colors[category.hashCode % colors.length];
}

class _LegendItem extends ConsumerWidget {
  final Color color;
  final String label;
  final double amount;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // color dot
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),

        // category
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),

        const SizedBox(width: 6),

        // arrow
        const Icon(
          Icons.arrow_right_alt,
          size: 16,
          color: Colors.grey,
        ),

        // amount
        Text(
          NumberFormat.compactCurrency(
            symbol: currency.currency.symbol,
            decimalDigits: 1,
          ).format(amount),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

pw.Widget _pdfRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(
          value,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}

String formatMoney(double amount, AppCurrency currency) {
  return NumberFormat.currency(
    symbol: currency.symbol,
    decimalDigits: 2,
  ).format(amount);
}

List<DateTime> _lastSixMonths(DateTime from) {
  return List.generate(
    6,
        (i) => DateTime(from.year, from.month - i),
  );
}

Map<DateTime, Map<String, double>> _groupExpensesByMonthAndCategory(
    List expenses,
    DateTime fromMonth,
    ) {
  final months = _lastSixMonths(fromMonth);

  final Map<DateTime, Map<String, double>> result = {};

  for (final month in months) {
    result[month] = {};
  }

  for (final e in expenses) {
    final expenseMonth = DateTime(e.date.year, e.date.month);

    if (!result.containsKey(expenseMonth)) continue;

    result[expenseMonth]![e.category] =
        (result[expenseMonth]![e.category] ?? 0) + e.amount;
  }

  return result;
}

pw.TableRow _tableRow(String label, String value) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(label),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          value,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );
}



