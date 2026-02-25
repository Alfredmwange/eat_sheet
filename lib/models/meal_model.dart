import 'package:eat_sheet/models/food_model.dart';

class Meal {
  final String id;
  final String userId;
  final DateTime date;
  final String mealType; // breakfast, lunch, dinner, snack
  final List<MealItem> foodItems;
  final Nutrients totalNutrients;
  final DateTime createdAt;

  Meal({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.foodItems,
    required this.totalNutrients,
    required this.createdAt,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      mealType: json['mealType'] ?? 'snack',
      foodItems: (json['foodItems'] as List?)?.map((item) => MealItem.fromJson(item)).toList() ?? [],
      totalNutrients: Nutrients.fromJson(json['totalNutrients'] ?? {}),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'mealType': mealType,
      'foodItems': foodItems.map((item) => item.toJson()).toList(),
      'totalNutrients': totalNutrients.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MealItem {
  final String foodId;
  final String foodName;
  final double quantity;
  final String unit;
  final Nutrients nutrients;

  MealItem({
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.nutrients,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      foodId: json['foodId'] ?? '',
      foodName: json['foodName'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'grams',
      nutrients: Nutrients.fromJson(json['nutrients'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'quantity': quantity,
      'unit': unit,
      'nutrients': nutrients.toJson(),
    };
  }
}