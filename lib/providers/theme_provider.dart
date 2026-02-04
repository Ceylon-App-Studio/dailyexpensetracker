import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final themeProvider =
ChangeNotifierProvider<ThemeNotifier>((ref) {
  return ThemeNotifier()..load();
});

class ThemeNotifier extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _key = 'dark_mode';

  late final Box _box;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    _box = Hive.box(_boxName);
    _isDarkMode = _box.get(_key, defaultValue: false);
    notifyListeners();
  }

  Future<void> toggle(bool value) async {
    _isDarkMode = value;
    await _box.put(_key, value);
    notifyListeners();
  }
}
