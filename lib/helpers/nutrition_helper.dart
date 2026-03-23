class NutritionHelper {
  /// Harris-Benedict TDEE then adjusts for goal
  static double calculateTDEE({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
  }) {
    // BMR
    double bmr;
    if (gender.toLowerCase() == 'female') {
      bmr = 447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * age);
    } else {
      bmr = 88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * age);
    }

    // Activity multiplier
    const multipliers = {
      'sedentary':  1.2,
      'light':      1.375,
      'moderate':   1.55,
      'active':     1.725,
      'veryactive': 1.9,
    };
    final multiplier = multipliers[activityLevel.toLowerCase()] ?? 1.55;
    return bmr * multiplier;
  }

  // Calorie target adjusted for goal
  static int dailyCalorieGoal({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    final tdee = calculateTDEE(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
    );

    switch (goal.toLowerCase()) {
      case 'lose_weight': return (tdee - 500).round().clamp(1200, 99999);
      case 'gain_weight': return (tdee + 300).round();
      default:            return tdee.round(); // maintain
    }
  }

  /// Macro targets in grams based on calorie goal
  static Map<String, int> macroGoals(int calories) {
    // 30% protein, 40% carbs, 30% fat  (standard balanced split)
    final protein = ((calories * 0.30) / 4).round(); // 4 kcal/g
    final carbs   = ((calories * 0.40) / 4).round();
    final fat     = ((calories * 0.30) / 9).round(); // 9 kcal/g
    return {'protein': protein, 'carbs': carbs, 'fat': fat};
  }
}