import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dailyexpensetracker/main_shell.dart';
import 'package:dailyexpensetracker/models/app_currency.dart';
import 'package:dailyexpensetracker/models/subscription.dart';
import 'package:dailyexpensetracker/providers/theme_provider.dart';
import 'enums/category_type.dart';
import 'models/category.dart';
import 'models/expense.dart';
import 'models/income.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(AppCurrencyAdapter());
  Hive.registerAdapter(CategoryTypeAdapter());

  Hive.registerAdapter(SubscriptionTypeAdapter());
  Hive.registerAdapter(SubscriptionAdapter());

  await Hive.openBox<Category>('categories');
  await Hive.openBox<Income>('incomeBox');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox('settings');
  await Hive.openBox<Subscription>('subscription');

  runApp(
    const ProviderScope(
      child: DailyExpenseTrackerApp(),
    ),
  );
}

class DailyExpenseTrackerApp extends ConsumerWidget {

  const DailyExpenseTrackerApp({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Expense Tracker',
      themeMode: theme.themeMode,

      theme: ThemeData(
        useMaterial3: true, // ✅ ENABLE MATERIAL 3
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D6F), // your brand teal
          brightness: Brightness.light,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true, // ✅ ENABLE MATERIAL 3
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D6F),
          brightness: Brightness.dark,
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (_) => const OnboardingScreen(),
        '/main': (_) => const MainShell(),
        '/home': (_) => const HomeScreen(),
        '/add-expense': (_) => const AddExpenseScreen(),
        '/summary': (_) => const SummaryScreen(),
        '/categories': (_) => const CategoriesScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}