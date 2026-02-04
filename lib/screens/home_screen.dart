import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dailyexpensetracker/screens/subscription_screen.dart';

import '../main.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/category_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/extensions.dart';
import '../widgets/premium_badge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime? _selectedDate;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // =======================
  // TRUE CLOSING BALANCE
  // =======================
  double _closingBalanceFor(
    DateTime date,
    List<Income> incomes,
    List<Expense> expenses,
  ) {
    final prevDay = DateTime(date.year, date.month, date.day - 1);

    final prevIncome = incomes
        .where((i) => _isSameDay(i.date, prevDay))
        .fold<double>(0, (s, i) => s + i.amount);

    final prevExpense = expenses
        .where((e) => _isSameDay(e.date, prevDay))
        .fold<double>(0, (s, e) => s + e.amount);

    if (prevIncome == 0 && prevExpense == 0) return 0;

    return _closingBalanceFor(prevDay, incomes, expenses) +
        prevIncome -
        prevExpense;
  }

  // =======================
  // DATE PICKER
  // =======================
  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 380,
          child: CalendarDatePicker(
            initialDate: _selectedDate ?? now,
            firstDate: DateTime(now.year - 5),
            lastDate: DateTime(now.year, now.month, now.day),
            onDateChanged: (d) {
              Navigator.pop(context);
              setState(() => _selectedDate = d);
            },
          ),
        ),
      ),
    );
  }

  void _resetToToday() => setState(() => _selectedDate = null);

  void _goToPreviousDay() {
    final base = _selectedDate ?? DateTime.now();
    setState(
      () => _selectedDate = DateTime(base.year, base.month, base.day - 1),
    );
  }

  void _goToNextDay() {
    final today = DateTime.now();
    final base = _selectedDate ?? today;
    final next = DateTime(base.year, base.month, base.day + 1);

    if (_isSameDay(next, today)) {
      _resetToToday();
    } else if (next.isBefore(today)) {
      setState(() => _selectedDate = next);
    }
  }

  // =======================
  // DELETE CONFIRMATION
  // =======================
  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showDeleteSnackbar(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = ScaffoldMessenger.of(context);

      messenger.clearSnackBars();

      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final incomes = ref.watch(incomeProvider);
    final categories = ref.watch(categoryProvider);
    final currency = ref.watch(currencyProvider).currency;

    final today = DateTime.now();
    final activeDate = _selectedDate ?? today;
    final isToday = _selectedDate == null;

    final todaysExpenses = expenses
        .where((e) => _isSameDay(e.date, activeDate))
        .toList();
    final todaysIncome = incomes
        .where((i) => _isSameDay(i.date, activeDate))
        .toList();

    final openingBalance = _closingBalanceFor(activeDate, incomes, expenses);

    final todaysIncomeWithBalance = [
      if (openingBalance != 0)
        Income(
          amount: openingBalance,
          source: 'Opening Balance',
          note: 'Opening Balance',
          date: activeDate,
        ),
      ...todaysIncome,
    ];

    final totalIncome = todaysIncomeWithBalance.fold<double>(
      0,
      (s, i) => s + i.amount,
    );
    final totalExpense = todaysExpenses.fold<double>(0, (s, e) => s + e.amount);

    final balance = totalIncome - totalExpense;
    final balanceColor = balance >= 0
        ? Theme.of(context).colorScheme.primary
        : Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              /*final isPremium =
                  ref.watch(subscriptionProvider.notifier).isPremium;*/

              //if (!isPremium) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  child: const PremiumBadge(fontSize: 10),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/add-expense',
            arguments: _selectedDate,
          );
        },
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(context, isToday, activeDate),
            if (!isToday)
              Center(
                child: TextButton(
                  onPressed: _resetToToday,
                  child: const Text('Back to Today'),
                ),
              ),
            const SizedBox(height: 12),
            _buildSummary(
              currency.symbol,
              totalIncome,
              totalExpense,
              balance,
              balanceColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // =======================
            // INCOME
            // =======================
            if (todaysIncomeWithBalance.isNotEmpty) ...[
              const _SectionHeader('Income'),
              ...todaysIncomeWithBalance.map((income) {
                final isOpeningBalance = income.source == 'Opening Balance';

                final tile = ListTile(
                  leading: Icon(Icons.account_balance, color: Colors.green),
                  title: Text(income.source ?? 'Other'),
                  trailing: Text(
                    '${currency.symbol} ${income.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );

                // 🚫 Opening Balance: NO swipe
                if (isOpeningBalance) {
                  return tile;
                }

                return Dismissible(
                  key: ValueKey('income-${income.hashCode}'),
                  background: _EditBackground(),
                  secondaryBackground: _DeleteBackground(),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      return await _confirmDelete(context);
                    }

                    if (direction == DismissDirection.startToEnd) {
                      Navigator.pushNamed(
                        context,
                        '/add-expense',
                        arguments: income,
                      );
                      return false;
                    }

                    return false;
                  },

                  onDismissed: (_) {
                    ref.read(incomeProvider.notifier).deleteIncome(income);

                    _showDeleteSnackbar(context, 'Income deleted');
                  },


                  child: tile,
                );
              }),
            ],

            // =======================
            // EXPENSES
            // =======================
            if (todaysExpenses.isNotEmpty) ...[
              const _SectionHeader('Expenses'),
              ...todaysExpenses.map((expense) {
                final category = categories.firstWhereOrNull(
                  (c) => c.name == expense.category,
                );

                return Dismissible(
                  key: ValueKey('expense-${expense.hashCode}'),
                  background: _EditBackground(),
                  secondaryBackground: _DeleteBackground(),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      return await _confirmDelete(context);
                    }

                    if (direction == DismissDirection.startToEnd) {
                      Navigator.pushNamed(
                        context,
                        '/add-expense',
                        arguments: expense,
                      );
                      return false;
                    }

                    return false;
                  },

                  onDismissed: (_) {
                    ref.read(expenseProvider.notifier).deleteExpense(expense);

                    _showDeleteSnackbar(context, 'Expense deleted');
                  },


                  child: ListTile(
                    leading: Icon(
                      category?.icon ?? Icons.category,
                      color: Colors.red,
                    ),
                    title: Text(expense.category),
                    trailing: Text(
                      '${currency.symbol} ${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ],

            if (todaysIncome.isEmpty && todaysExpenses.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'No income or expenses for this day',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 120),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(
    BuildContext context,
    bool isToday,
    DateTime activeDate,
  ) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _goToPreviousDay,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(context),
            child: Column(
              children: [
                Text(
                  isToday ? 'Today' : 'Selected Day',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMM d').format(activeDate),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isToday ? null : _goToNextDay,
        ),
      ],
    );
  }

  Widget _buildSummary(
    String symbol,
    double income,
    double expense,
    double balance,
    Color balanceColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              title: 'Income',
              amount: income,
              color: Colors.green,
              currency: symbol,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryTile(
              title: 'Expense',
              amount: expense,
              color: Colors.red,
              currency: symbol,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryTile(
              title: 'Balance',
              amount: balance,
              color: balanceColor,
              currency: symbol,
            ),
          ),
        ],
      ),
    );
  }
}

// =======================
// SUPPORT WIDGETS
// =======================
class _SummaryTile extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String currency;

  const _SummaryTile({
    required this.title,
    required this.amount,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 👈 KEY LINE
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _AnimatedAmount(
              value: amount,
              color: color,
              symbol: currency,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _EditBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: Colors.blue,
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.red,
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

class _AnimatedAmount extends StatelessWidget {
  final double value;
  final Color color;
  final String symbol;

  const _AnimatedAmount({
    required this.value,
    required this.color,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(
          '$symbol ${animatedValue.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
