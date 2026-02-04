import 'package:hive/hive.dart';

part 'category_type.g.dart';

@HiveType(typeId: 5)
enum CategoryType {
  @HiveField(0)
  expense,

  @HiveField(1)
  income,
}
