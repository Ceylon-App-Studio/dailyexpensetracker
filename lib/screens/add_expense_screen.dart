import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailyexpensetracker/models/app_currency.dart';

import '../enums/EntryType.dart';
import '../enums/category_type.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../providers/category_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCategory;
  late DateTime _selectedDate;
  bool _dateInitialized = false;

  EntryType _entryType = EntryType.expense;
  Expense? _editingExpense;
  Income? _editingIncome;

  bool get _isEditing =>
      _editingExpense != null || _editingIncome != null;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // =======================
  // DATE FROM HOME / EDIT
  // =======================
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_dateInitialized) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Expense) {
      _entryType = EntryType.expense;
      _editingExpense = args;
      _amountController.text = args.amount.toString();
      _noteController.text = args.note ?? '';
      _selectedCategory = args.category;
      _selectedDate = args.date;
    } else if (args is Income) {
      _entryType = EntryType.income;
      _editingIncome = args;
      _amountController.text = args.amount.toString();
      _noteController.text = args.note ?? '';
      _selectedCategory = args.source;
      _selectedDate = args.date;
    } else {
      _selectedDate = args is DateTime ? args : DateTime.now();
    }

    _dateInitialized = true;
  }

  // =======================
  // DEFAULT CATEGORY
  // =======================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isEditing && _selectedCategory == null) {
        _setDefaultCategory();
      }
    });
  }

  void _setDefaultCategory() {
    if (_isEditing) return;

    final categories = ref.read(categoryProvider);
    if (categories.isEmpty) return;

    if (_entryType == EntryType.expense) {
      final misc = categories.firstWhere(
            (c) =>
        c.type == CategoryType.expense &&
            c.name.toLowerCase() == 'miscellaneous',
        orElse: () =>
            categories.firstWhere((c) => c.type == CategoryType.expense),
      );
      setState(() => _selectedCategory = misc.name);
    } else {
      final salary = categories.firstWhere(
            (c) =>
        c.type == CategoryType.income &&
            c.name.toLowerCase() == 'salary',
        orElse: () =>
            categories.firstWhere((c) => c.type == CategoryType.income),
      );
      setState(() => _selectedCategory = salary.name);
    }
  }

  // =======================
  // BUILD
  // =======================
  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final currency = ref.watch(currencyProvider).currency;

    final filteredCategories = categories
        .where(
          (c) => _entryType == EntryType.expense
          ? c.type == CategoryType.expense
          : c.type == CategoryType.income,
    )
        .map((c) => c.name)
        .toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _entryType == EntryType.expense ? 'Add Expense' : 'Add Income',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: _saveBar(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _entryTypeToggle(),
              const SizedBox(height: 16),
              _amountField(currency),
              const SizedBox(height: 12),
              _categoryPicker(context, filteredCategories),
              const SizedBox(height: 12),
              _inputField('Note', _noteController),
              const SizedBox(height: 12),
              _datePicker(context),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // =======================
  // CATEGORY PICKER
  // =======================
  Widget _categoryPicker(
      BuildContext context,
      List<String> categories,
      ) {
    return InkWell(
      onTap: () => _showCategoryBottomSheet(context, categories),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(),
        ),
        child: Text(
          _selectedCategory ?? 'Select category',
          style: TextStyle(
            color: _selectedCategory == null ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(
      BuildContext context,
      List<String> categories,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final searchController = TextEditingController();
        List<String> filtered = List.from(categories);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void filter(String query) {
              setSheetState(() {
                filtered = categories
                    .where((c) =>
                    c.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom:
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search category',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: filter,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filtered.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return ListTile(
                            leading: const Icon(Icons.add),
                            title: const Text('Add new category'),
                            onTap: () async {
                              Navigator.pop(sheetContext);

                              final newCategory =
                              await Navigator.pushNamed(
                                context,
                                '/categories',
                                arguments: {
                                  'autoOpenAdd': true,
                                  'lockedType':
                                  _entryType == EntryType.expense
                                      ? CategoryType.expense
                                      : CategoryType.income,
                                },
                              );

                              if (newCategory is String) {
                                setState(() {
                                  _selectedCategory = newCategory;
                                });
                              }
                            },
                          );
                        }

                        final category = filtered[index - 1];
                        return ListTile(
                          title: Text(category),
                          onTap: () {
                            setState(() => _selectedCategory = category);
                            Navigator.pop(sheetContext);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =======================
  // SAVE BAR
  // =======================
  Widget _saveBar(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.fromLTRB(16, 8, 16, inset + 8),
      child: FilledButton(
        onPressed: () => _saveEntry(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // =======================
  // ENTRY TYPE
  // =======================
  Widget _entryTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: _EntryTypeButton(
            label: 'Income',
            selected: _entryType == EntryType.income,
            onTap: () {
              setState(() => _entryType = EntryType.income);
              _setDefaultCategory();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _EntryTypeButton(
            label: 'Expense',
            selected: _entryType == EntryType.expense,
            onTap: () {
              setState(() => _entryType = EntryType.expense);
              _setDefaultCategory();
            },
          ),
        ),
      ],
    );
  }

  // =======================
  // AMOUNT
  // =======================
  Widget _amountField(AppCurrency currency) {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Amount ${currency.symbol}',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // =======================
  // DATE PICKER
  // =======================
  Widget _datePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        await showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              height: 380,
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(now.year, now.month, now.day),
                onDateChanged: (picked) {
                  Navigator.pop(context);
                  setState(() => _selectedDate = picked);
                },
              ),
            ),
          ),
        );
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        ),
      ),
    );
  }

  // =======================
  // SAVE LOGIC
  // =======================
  Future<void> _saveEntry(BuildContext context) async {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount and Category required')),
      );
      return;
    }

    if (_entryType == EntryType.expense) {
      final expense = Expense(
        amount: amount,
        category: _selectedCategory!,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );

      if (_editingExpense != null) {
        await ref.read(expenseProvider.notifier).updateExpense(
          oldExpense: _editingExpense!,
          newExpense: expense,
        );
      } else {
        await ref.read(expenseProvider.notifier).addExpense(expense);
      }
    } else {
      final income = Income(
        amount: amount,
        source: _selectedCategory!,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );

      if (_editingIncome != null) {
        await ref.read(incomeProvider.notifier).updateIncome(
          oldIncome: _editingIncome!,
          newIncome: income,
        );
      } else {
        await ref.read(incomeProvider.notifier).addIncome(income);
      }
    }

    Navigator.pop(context);
  }
}

// =======================
// SUPPORT WIDGET
// =======================
class _EntryTypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EntryTypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
