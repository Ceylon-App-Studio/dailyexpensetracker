import 'package:hive/hive.dart';

part 'subscription.g.dart';

@HiveType(typeId: 30)
enum SubscriptionType {
  @HiveField(0)
  none,

  @HiveField(1)
  monthly,

  @HiveField(2)
  yearly,
}

@HiveType(typeId: 31)
class Subscription {
  @HiveField(0)
  final SubscriptionType type;

  @HiveField(1)
  final DateTime startDate;

  @HiveField(2)
  final DateTime endDate;

  Subscription({
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  bool get isActive => DateTime.now().isBefore(endDate);
}
