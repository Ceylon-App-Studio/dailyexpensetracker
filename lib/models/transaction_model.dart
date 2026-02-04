import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 3)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final bool isIncome;

  @HiveField(3)
  final DateTime date;

  TransactionModel({
    required this.amount,
    required this.category,
    required this.isIncome,
    required this.date,
  });
}
