class Food {
  final String id;
  final String name;
  final String? localName; // Swahili or local name
  final String description;
  final double servingSize;
  final String unit; // grams, ml, piece, cup, etc.
  final Nutrients nutrients;
  final DateTime createdAt;

  Food({
    required this.id,
    required this.name,
    this.localName,
    required this.description,
    required this.servingSize,
    required this.unit,
    required this.nutrients,
    required this.createdAt,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      localName: json['localName'],
      description: json['description'] ?? '',
      servingSize: (json['servingSize'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'grams',
      nutrients: Nutrients.fromJson(json['nutrients'] ?? {}),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'localName': localName,
      'description': description,
      'servingSize': servingSize,
      'unit': unit,
      'nutrients': nutrients.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Nutrients {
  final double carbohydrates; // grams
  final double protein; // grams
  final double fat; // grams
  final double calories; // kcal
  final double iron; // mg
  final double vitaminA; // mcg
  final double zinc; // mg
  final double calcium; // mg
  final double fiber; // grams

  Nutrients({
    required this.carbohydrates,
    required this.protein,
    required this.fat,
    required this.calories,
    required this.iron,
    required this.vitaminA,
    required this.zinc,
    required this.calcium,
    required this.fiber,
  });

  factory Nutrients.fromJson(Map<String, dynamic> json) {
    return Nutrients(
      carbohydrates: (json['carbohydrates'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      calories: (json['calories'] ?? 0).toDouble(),
      iron: (json['iron'] ?? 0).toDouble(),
      vitaminA: (json['vitaminA'] ?? 0).toDouble(),
      zinc: (json['zinc'] ?? 0).toDouble(),
      calcium: (json['calcium'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carbohydrates': carbohydrates,
      'protein': protein,
      'fat': fat,
      'calories': calories,
      'iron': iron,
      'vitaminA': vitaminA,
      'zinc': zinc,
      'calcium': calcium,
      'fiber': fiber,
    };
  }
}