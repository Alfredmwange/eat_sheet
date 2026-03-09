import 'package:flutter/material.dart';
import '../../helpers/datetime_helper.dart';

class HomeScreen extends StatelessWidget {
  final String username;
  final int currentCalories;
  final int dailyGoal;
  final Map<String, int> mealCalories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;
  final void Function(String meal) onMealTap;

  const HomeScreen({
    super.key,
    required this.username,
    this.currentCalories = 500,
    this.dailyGoal = 2000,
    this.mealCalories = const {
      'Breakfast': 0,
      'Lunch': 0,
      'Snacks': 0,
      'Dinner': 0,
    },
    this.proteinGrams = 65,
    this.carbsGrams = 150,
    this.fatGrams = 50,
    this.proteinGoal = 100,
    this.carbsGoal = 250,
    this.fatGoal = 70,
    required this.onMealTap,
  });

  double _percent(int value, int goal) {
    if (goal <= 0) return 0;
    return (value / goal).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final greetingName = username.split(' ').first; // show first name only
    final today = DateTime.now();
    final calorieProgress = _percent(currentCalories, dailyGoal);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Hello, $greetingName 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateTimeHelper.formatDate(today),
                style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
              ),

              const SizedBox(height: 24),

              // Calorie Progress
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: calorieProgress,
                        strokeWidth: 12,
                        color: Colors.blue.shade600,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$currentCalories',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '/ $dailyGoal calories',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Today's Meals
              const Text(
                "Today's Meals",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 31, 134, 225)),
              ),
              const SizedBox(height: 12),
              Column(
                children: mealCalories.entries.map((entry) {
                  return MealCard(
                    icon: _iconForMeal(entry.key),
                    mealName: entry.key,
                    calories: entry.value,
                    onTap: () => onMealTap(entry.key),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Macronutrients
              const Text(
                'Macronutrients',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 31, 134, 225)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MacroProgress(
                    label: 'Protein',
                    consumed: proteinGrams,
                    goal: proteinGoal,
                    color: Colors.green,
                  ),
                  MacroProgress(
                    label: 'Carbs',
                    consumed: carbsGrams,
                    goal: carbsGoal,
                    color: Colors.orange,
                  ),
                  MacroProgress(
                    label: 'Fat',
                    consumed: fatGrams,
                    goal: fatGoal,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForMeal(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'snacks':
        return Icons.fastfood;
      case 'dinner':
        return Icons.restaurant;
      default:
        return Icons.restaurant_menu;
    }
  }
}

// Reusable meal card widget
class MealCard extends StatelessWidget {
  final IconData icon;
  final String mealName;
  final int calories;
  final VoidCallback onTap;

  const MealCard({
    super.key,
    required this.icon,
    required this.mealName,
    required this.calories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 28, color:  Color.fromARGB(255, 32, 142, 238)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  mealName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text('$calories cal', style: TextStyle(color: const Color.fromARGB(255, 26, 26, 26))),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color.fromARGB(255, 32, 142, 238)),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable macro progress widget
class MacroProgress extends StatelessWidget {
  final String label;
  final int consumed;
  final int goal;
  final Color color;

  const MacroProgress({
    super.key,
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = goal > 0 ? (consumed / goal).clamp(0, 1).toDouble() : 0.0;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: percent,
                strokeWidth: 6,
                color: color,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            Text(
              '$consumed',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
