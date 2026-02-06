import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailyexpensetracker/providers/income_provider.dart';

import '../enums/category_type.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  bool _incomeExpanded = true;
  bool _expenseExpanded = true;

  bool _autoOpenAdd = false;
  CategoryType? _lockedType;
  bool _dialogOpened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      _autoOpenAdd = args['autoOpenAdd'] == true;
      _lockedType = args['lockedType'];
    }

    if (_autoOpenAdd && !_dialogOpened) {
      _dialogOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddDialog(context);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final expenses = ref.watch(expenseProvider);
    final incomes = ref.watch(incomeProvider);

    final incomeCategories =
    categories.where((c) => c.type == CategoryType.income).toList();

    final expenseCategories =
    categories.where((c) => c.type == CategoryType.expense).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Categories',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _lockedType = null;
              _showAddDialog(context);
            },
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 120),
        children: [
          // =======================
          // INCOME CATEGORIES
          // =======================
          if (incomeCategories.isNotEmpty) ...[
            _CollapsibleHeader(
              title: 'Income Categories',
              expanded: _incomeExpanded,
              onTap: () {
                setState(() => _incomeExpanded = !_incomeExpanded);
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _incomeExpanded
                  ? Column(
                children: incomeCategories.map((category) {
                  final usageCount = incomes
                      .where((e) => e.source == category.name)
                      .length;

                  return ListTile(
                    leading: Icon(
                      category.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(category.name),
                    subtitle: Text('$usageCount transactions'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blueGrey),
                          onPressed: () => _showEditDialog(
                            context,
                            category,
                            category.name,
                          ),
                        ),
                        Tooltip(
                          message: usageCount > 0
                              ? 'Category is used in $usageCount transactions'
                              : 'Delete category',
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            color: usageCount > 0
                                ? Colors.grey
                                : Colors.red,
                            onPressed: () {
                              if (usageCount > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Category is used in $usageCount transactions',
                                    ),
                                  ),
                                );
                                return;
                              }
                              _showDeleteDialog(context, category);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
                  : const SizedBox.shrink(),
            ),
          ],

          // =======================
          // EXPENSE CATEGORIES
          // =======================
          if (expenseCategories.isNotEmpty) ...[
            _CollapsibleHeader(
              title: 'Expense Categories',
              expanded: _expenseExpanded,
              onTap: () {
                setState(() => _expenseExpanded = !_expenseExpanded);
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _expenseExpanded
                  ? Column(
                children: expenseCategories.map((category) {
                  final isMisc =
                      category.name.toLowerCase() == 'miscellaneous';

                  final expenseCount = expenses
                      .where((e) => e.category == category.name)
                      .length;

                  return ListTile(
                    leading: Icon(
                      category.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(category.name),
                    subtitle: Text('$expenseCount transactions'),
                    trailing: isMisc
                        ? null
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blueGrey),
                          onPressed: () => _showEditDialog(
                            context,
                            category,
                            category.name,
                          ),
                        ),
                        Tooltip(
                          message: expenseCount > 0
                              ? 'Category is used in $expenseCount transactions'
                              : 'Delete category',
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            color: expenseCount > 0
                                ? Colors.grey
                                : Colors.red,
                            onPressed: () {
                              if (expenseCount > 0) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Category is used in $expenseCount transactions',
                                    ),
                                  ),
                                );
                                return;
                              }
                              _showDeleteDialog(context, category);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  // =======================
  // ADD CATEGORY
  // =======================
  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    CategoryType selectedType = _lockedType ?? CategoryType.expense;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Add Category',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== TYPE (LOCKED IF PROVIDED) =====
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Expense'),
                              selected: selectedType == CategoryType.expense,
                              onSelected: (_lockedType == null ||
                                  _lockedType == CategoryType.expense)
                                  ? (_) {
                                setSheetState(() {
                                  selectedType = CategoryType.expense;
                                });
                              }
                                  : null,
                              disabledColor: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Income'),
                              selected: selectedType == CategoryType.income,
                              onSelected: (_lockedType == null ||
                                  _lockedType == CategoryType.income)
                                  ? (_) {
                                setSheetState(() {
                                  selectedType = CategoryType.income;
                                });
                              }
                                  : null,
                              disabledColor: Colors.grey.shade200,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final name = controller.text.trim();
                            if (name.isEmpty) return;

                            final success = await ref
                                .read(categoryProvider.notifier)
                                .addCategory(name, selectedType);

                            Navigator.pop(sheetContext);

                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Category already exists'),
                                ),
                              );
                              return;
                            }

                            // ✅ RETURN NEW CATEGORY
                            Navigator.pop(context, name);
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
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
  // EDIT CATEGORY
  // =======================
  void _showEditDialog(
      BuildContext context, Category category, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Category name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                final success = await ref
                    .read(categoryProvider.notifier)
                    .editCategory(category, newName);

                Navigator.pop(dialogContext);

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category name already exists'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // =======================
  // DELETE CATEGORY
  // =======================
  void _showDeleteDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await ref
                  .read(categoryProvider.notifier)
                  .deleteCategory(category);

              Navigator.pop(dialogContext);

              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                    Text('Category cannot be deleted (in use or protected)'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// =======================
// COLLAPSIBLE HEADER
// =======================
class _CollapsibleHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;

  const _CollapsibleHeader({
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
