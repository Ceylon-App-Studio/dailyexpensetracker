import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../constants/category_icons.dart';
import '../enums/category_type.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String iconCode;

  // ✅ NEW FIELD
  @HiveField(2)
  final CategoryType type;

  Category({
    required this.name,
    required this.iconCode,
    required this.type,
  });

  IconData get icon {
    switch (iconCode) {
    // Expense
      case 'food':
        return CategoryIcons.food;
      case 'groceries':
        return CategoryIcons.groceries;
      case 'cooking':
        return CategoryIcons.cooking;
      case 'clothing':
        return CategoryIcons.clothing;
      case 'hygiene':
        return CategoryIcons.hygiene;
      case 'skinCare':
        return CategoryIcons.skinCare;
      case 'health':
        return CategoryIcons.health;
      case 'transport':
        return CategoryIcons.transport;
      case 'telecom':
        return CategoryIcons.telecom;
      case 'creditCard':
        return CategoryIcons.creditCard;
      case 'loan':
        return CategoryIcons.loan;
      case 'rent':
        return CategoryIcons.rent;
      case 'utilities':
        return CategoryIcons.utilities;

    // Income
      case 'salary':
        return CategoryIcons.salary;
      case 'bonus':
        return CategoryIcons.bonus;
      case 'freelance':
        return CategoryIcons.freelance;
      case 'socialMedia':
        return CategoryIcons.socialMedia;
      case 'gift':
        return CategoryIcons.gift;

      default:
        return CategoryIcons.miscellaneous;
    }
  }

}
