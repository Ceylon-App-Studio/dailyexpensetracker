import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/income.dart';
import '../services/icome_hive_service.dart';

final incomeProvider =
StateNotifierProvider<IncomeNotifier, List<Income>>(
      (ref) => IncomeNotifier(),
);

class IncomeNotifier extends StateNotifier<List<Income>> {
  IncomeNotifier() : super(IncomeHiveService.loadIncome());

  Future<void> addIncome(Income income) async {
    await IncomeHiveService.addIncome(income);
    state = IncomeHiveService.getAll();
  }

  Future<void> deleteIncome(Income income) async {
    await IncomeHiveService.deleteIncome(income);
    state = IncomeHiveService.getAll();
  }

  Future<void> updateIncome({
    required Income oldIncome,
    required Income newIncome,
  }) async {
    await IncomeHiveService.updateIncome(
      oldIncome: oldIncome,
      newIncome: newIncome,
    );
    state = IncomeHiveService.getAll();
  }


}
