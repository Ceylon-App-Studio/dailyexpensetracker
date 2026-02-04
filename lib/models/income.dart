import 'package:hive/hive.dart';

part 'income.g.dart';

@HiveType(typeId: 2)
class Income extends HiveObject {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final String note;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String source;

  Income({
    required this.amount,
    required this.note,
    required this.date,
    required this.source,
  });
}
