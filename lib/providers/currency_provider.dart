import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/app_currency.dart';

final currencyProvider =
ChangeNotifierProvider<CurrencyNotifier>((ref) {
  return CurrencyNotifier()..load();
});

class CurrencyNotifier extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _key = 'currency';

  late final Box _box;

  AppCurrency _currency = supportedCurrencies.first;
  AppCurrency get currency => _currency;

  Future<void> load() async {
    _box = Hive.box(_boxName);

    final savedCurrency = _box.get(_key) as AppCurrency?;

    if (savedCurrency != null) {
      _currency = savedCurrency;
    }

    notifyListeners();
  }

  Future<void> setCurrency(AppCurrency newCurrency) async {
    _currency = newCurrency;
    await _box.put(_key, newCurrency);
    notifyListeners();
  }
}
