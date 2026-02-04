import 'package:hive/hive.dart';

part 'app_currency.g.dart';

@HiveType(typeId: 4)
class AppCurrency {
  @HiveField(0)
  final String code;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String symbol;

  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AppCurrency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

const supportedCurrencies = [
  AppCurrency(
    code: 'LKR',
    name: 'Sri Lankan Rupee',
    symbol: 'Rs',
  ),
  AppCurrency(
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
  ),
  AppCurrency(
    code: 'USD',
    name: 'US Dollar',
    symbol: '\$',
  ),
  AppCurrency(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
  ),
  AppCurrency(
    code: 'GBP',
    name: 'British Pound',
    symbol: '£',
  ),
];
