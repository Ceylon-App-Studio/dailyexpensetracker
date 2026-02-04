import 'package:hive/hive.dart';
import '../models/income.dart';

class IncomeHiveService {
  static const _boxName = 'incomeBox';

  static Box<Income> get _box => Hive.box<Income>(_boxName);

  static List<Income> loadIncome() {
    return _box.values.toList();
  }

  /// ✅ Add single income
  static Future<void> addIncome(Income income) async {
    await _box.add(income);
  }

  /// ✅ Delete by key
  static Future<void> deleteIncome(Income income) async {
    final key = income.key;
    if (key != null) {
      await _box.delete(key);
    }
  }

  /// ✅ Read all
  static List<Income> getAll() {
    return _box.values.toList();
  }

  static Future<void> updateIncome({
    required Income oldIncome,
    required Income newIncome,
  }) async {
    final index = _box.values.toList().indexOf(oldIncome);
    if (index != -1) {
      await _box.putAt(index, newIncome);
    }
  }
}
