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
  static const _key = 'currency_code';

  late final Box _box;

  AppCurrency _currency = supportedCurrencies.first;
  bool _loaded = false;

  AppCurrency get currency => _currency;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _box = Hive.box(_boxName);

    final savedCode = _box.get(_key) as String?;

    if (savedCode != null) {
      _currency = supportedCurrencies.firstWhere(
            (c) => c.code == savedCode,
        orElse: () => supportedCurrencies.first,
      );
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> setCurrency(AppCurrency newCurrency) async {
    if (_currency.code == newCurrency.code) return;

    _currency = newCurrency;
    await _box.put(_key, newCurrency.code);

    notifyListeners();
  }
}
