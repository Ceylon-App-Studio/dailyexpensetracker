import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../enums/category_type.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int iconCode;

  // ✅ NEW FIELD
  @HiveField(2)
  final CategoryType type;

  Category({
    required this.name,
    required this.iconCode,
    required this.type,
  });

  IconData get icon => IconData(
    iconCode,
    fontFamily: 'MaterialIcons',
  );
}
