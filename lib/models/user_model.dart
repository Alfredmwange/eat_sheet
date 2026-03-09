class User {
  final String id;
  final String name;
  final String email;
  final int age;
  final double weight; // in kg
  final double height; // in cm
  final double goalWeight; // in kg
  final String gender; // male, female, other
  final String goal; // lose_weight, maintain, gain_weight
  final String? profilePicture; // URL to profile picture
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
    required this.goalWeight,
    required this.gender,
    required this.goal,
    this.profilePicture,
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
      goalWeight: (json['goalWeight'] ?? 0).toDouble(),
      gender: json['gender'] ?? 'other',
      goal: json['goal'] ?? 'maintain',
      profilePicture: json['profilePicture'],
      activityLevel: json['activityLevel'] ?? 'moderate',
      dietaryGoals: Map<String, double>.from(json['dietaryGoals'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
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
      'goalWeight': goalWeight,
      'gender': gender,
      'goal': goal,
      'profilePicture': profilePicture,
      'activityLevel': activityLevel,
      'dietaryGoals': dietaryGoals,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    double? weight,
    double? height,
    double? goalWeight,
    String? gender,
    String? goal,
    String? profilePicture,
    String? activityLevel,
    Map<String, double>? dietaryGoals,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goalWeight: goalWeight ?? this.goalWeight,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      profilePicture: profilePicture ?? this.profilePicture,
      activityLevel: activityLevel ?? this.activityLevel,
      dietaryGoals: dietaryGoals ?? this.dietaryGoals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
