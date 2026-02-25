class User {
  final String id;
  final String name;
  final String email;
  final int age;
  final double weight; // in kg
  final double height; // in cm
  final String activityLevel; // sedentary, light, moderate, active, veryActive
  final Map<String, double> dietaryGoals; // carbs, protein, fat targets
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.weight,
    required this.height,
    required this.activityLevel,
    required this.dietaryGoals,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 0,
      weight: (json['weight'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      activityLevel: json['activityLevel'] ?? 'moderate',
      dietaryGoals: Map<String, double>.from(json['dietaryGoals'] ?? {}),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'weight': weight,
      'height': height,
      'activityLevel': activityLevel,
      'dietaryGoals': dietaryGoals,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}