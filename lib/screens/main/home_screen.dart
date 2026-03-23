import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../helpers/datetime_helper.dart';
import '../../helpers/nutrition_helper.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../providers/user_provider.dart';
import '../../services/database.dart';
import 'add_meal.dart';

// HomeScreen 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, List<FoodEntry>> _logs = {
    'Breakfast': [],
    'Lunch': [],
    'Snacks': [],
    'Dinner': [],
  };

  final Map<String, bool> _expanded = {
    'Breakfast': false,
    'Lunch': false,
    'Snacks': false,
    'Dinner': false,
  };

  static const _logsKey = 'meal_logs_v1';
  static const _lastResetKey = 'last_reset_date_v1';

  @override
  void initState() {
    super.initState();
    _loadAndMaybeReset();
  }

  Future<void> _loadAndMaybeReset() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final lastResetStr = prefs.getString(_lastResetKey);
    final lastReset =
        lastResetStr != null ? DateTime.parse(lastResetStr) : null;

    final todayNoon = DateTime(now.year, now.month, now.day, 12, 0, 0);
    final mostRecentNoon = now.isAfter(todayNoon)
        ? todayNoon
        : todayNoon.subtract(const Duration(days: 1));

    final shouldReset =
        lastReset == null || lastReset.isBefore(mostRecentNoon);

    if (shouldReset) {
      for (final k in _logs.keys) {
        _logs[k] = [];
      }
      await prefs.setString(_lastResetKey, now.toIso8601String());
      await prefs.remove(_logsKey);
    } else {
      final raw = prefs.getString(_logsKey);
      if (raw != null) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((meal, list) {
          if (_logs.containsKey(meal)) {
            _logs[meal] = (list as List)
                .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        });
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveLogs() async {
    // Save locally
    final prefs = await SharedPreferences.getInstance();
    final logMap = _logs.map(
      (meal, entries) => MapEntry(meal, entries.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_logsKey, jsonEncode(logMap));

    // Sync to Firestore if signed in
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await DatabaseService().saveMealLog(uid, logMap);
    }
  }

  void _onFoodLogged(FoodEntry entry) {
    setState(() => _logs[entry.meal]?.add(entry));
    _saveLogs();
  }

  // ── Totals 
  int get _totalCalories =>
      _logs.values.expand((e) => e).fold<int>(0, (s, e) => s + e.calories);
  int get _totalProtein =>
      _logs.values.expand((e) => e).fold<int>(0, (s, e) => s + e.protein);
  int get _totalCarbs =>
      _logs.values.expand((e) => e).fold<int>(0, (s, e) => s + e.carbs);
  int get _totalFat =>
      _logs.values.expand((e) => e).fold<int>(0, (s, e) => s + e.fat);

  int _mealCalories(String meal) =>
      _logs[meal]?.fold<int>(0, (s, e) => s + e.calories) ?? 0;

  double _percent(int value, int goal) {
    if (goal <= 0) return 0;
    return (value / goal).clamp(0, 1).toDouble();
  }

  IconData _iconForMeal(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast': return Icons.free_breakfast;
      case 'lunch':     return Icons.lunch_dining;
      case 'snacks':    return Icons.fastfood;
      case 'dinner':    return Icons.restaurant;
      default:          return Icons.restaurant_menu;
    }
  }

  void _openAddMeal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMealScreen(onFoodLogged: _onFoodLogged),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;
        final today = DateTime.now();

        // ── Derive goals from user profile 
        int dailyGoal   = 2000;
        int proteinGoal = 100;
        int carbsGoal   = 250;
        int fatGoal     = 70;
        String greetingName = 'there';

        if (user != null) {
          greetingName = user.name.isNotEmpty
              ? user.name.split(' ').first
              : 'there';

          // If the user has manually set dietaryGoals, honour them.
          // Otherwise compute from profile using TDEE.
          if (user.dietaryGoals.containsKey('calories')) {
            dailyGoal   = user.dietaryGoals['calories']!.round();
            proteinGoal = (user.dietaryGoals['protein'] ?? 100).round();
            carbsGoal   = (user.dietaryGoals['carbs']   ?? 250).round();
            fatGoal     = (user.dietaryGoals['fat']     ?? 70).round();
          } else if (user.age > 0 && user.weight > 0 && user.height > 0) {
            // Auto-calculate
            dailyGoal = NutritionHelper.dailyCalorieGoal(
              weightKg:      user.weight,
              heightCm:      user.height,
              age:           user.age,
              gender:        user.gender,
              activityLevel: user.activityLevel,
              goal:          user.goal,
            );
            final macros = NutritionHelper.macroGoals(dailyGoal);
            proteinGoal = macros['protein']!;
            carbsGoal   = macros['carbs']!;
            fatGoal     = macros['fat']!;
          }
        }

        final calorieProgress = _percent(_totalCalories, dailyGoal);

        // ── Calorie status colour 
        Color ringColor;
        if (_totalCalories >= dailyGoal) {
          ringColor = Colors.red.shade400;
        } else if (_totalCalories >= dailyGoal * 0.85) {
          ringColor = Colors.orange.shade400;
        } else {
          ringColor = Colors.blue.shade600;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ────────────────────────────
                  Text(
                    'Hello, $greetingName 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).textTheme.headlineLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTimeHelper.formatDate(today),
                    style: const TextStyle(
                        color: Color(0xFF7A8EA0), fontSize: 13),
                  ),

                  const SizedBox(height: 24),

                  // ── Profile loading indicator 
                  if (userProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(),
                    ),

                  // ── Calorie ring 
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
                            color: ringColor,
                            backgroundColor: Colors.grey.shade300,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_totalCalories',
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '/ $dailyGoal kcal',
                              style:
                                  TextStyle(color: const Color.fromARGB(255, 26, 25, 25)),
                            ),
                            if (user != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                _goalLabel(user.goal),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color.fromARGB(255, 36, 35, 35),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── No profile nudge
                  if (user == null && !userProvider.isLoading) ...[
                    const SizedBox(height: 12),
                    _NudgeBanner(
                      onTap: () => Navigator.of(context)
                          .pushNamed('/complete-profile'),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Today's Meals 
                  const Text(
                    "Today's Meals",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F86E1)),
                  ),
                  const SizedBox(height: 12),

                  ..._logs.keys.map((meal) => _ExpandableMealCard(
                        icon: _iconForMeal(meal),
                        mealName: meal,
                        calories: _mealCalories(meal),
                        entries: _logs[meal]!,
                        isExpanded: _expanded[meal]!,
                        onToggle: () => setState(
                            () => _expanded[meal] = !_expanded[meal]!),
                      )),

                  const SizedBox(height: 10),

                  // ── Add Meal card 
                  GestureDetector(
                    onTap: _openAddMeal,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF1F86E1), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: Color(0xFF1F86E1), size: 24),
                          SizedBox(width: 10),
                          Text('Add Meal',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F86E1))),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Macronutrients 
                  const Text(
                    'Macronutrients',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F86E1)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MacroProgress(
                          label: 'Protein',
                          consumed: _totalProtein,
                          goal: proteinGoal,
                          color: Colors.green),
                      MacroProgress(
                          label: 'Carbs',
                          consumed: _totalCarbs,
                          goal: carbsGoal,
                          color: Colors.orange),
                      MacroProgress(
                          label: 'Fat',
                          consumed: _totalFat,
                          goal: fatGoal,
                          color: Colors.red),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '🔄 Data resets daily at Midnight',
                      style:
                          TextStyle(color: const Color.fromARGB(255, 84, 84, 84), fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _goalLabel(String goal) {
    switch (goal.toLowerCase()) {
      case 'lose_weight': return 'Goal: lose weight';
      case 'gain_weight': return 'Goal: gain weight';
      default:            return 'Goal: maintain weight';
    }
  }
}

// Nudge banner when no profile is set

class _NudgeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _NudgeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD700), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                color: Color(0xFF856404), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Complete your profile for personalised calorie and macro goals.',
                style: TextStyle(
                    color: const Color(0xFF856404),
                    fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF856404), size: 18),
          ],
        ),
      ),
    );
  }
}

// Expandable Meal Card

class _ExpandableMealCard extends StatelessWidget {
  final IconData icon;
  final String mealName;
  final int calories;
  final List<FoodEntry> entries;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExpandableMealCard({
    required this.icon,
    required this.mealName,
    required this.calories,
    required this.entries,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 28, color: const Color(0xFF208EEE)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(mealName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Text('$calories cal',
                      style:
                          const TextStyle(color: Color(0xFF1A1A1A))),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.chevron_right,
                        color: Color(0xFF208EEE)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: Color(0xFFEAF2FB))),
                    ),
                    child: entries.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('No items logged yet.',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          )
                        : Column(
                            children: entries
                                .map((e) => _FoodEntryRow(entry: e))
                                .toList(),
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _FoodEntryRow extends StatelessWidget {
  final FoodEntry entry;
  const _FoodEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(entry.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Text('${entry.calories} cal',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1F86E1))),
          const SizedBox(width: 10),
          Text(
            'P:${entry.protein}g  C:${entry.carbs}g  F:${entry.fat}g',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// MacroProgress

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
    final percent =
        goal > 0 ? (consumed / goal).clamp(0, 1).toDouble() : 0.0;
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
            Text('$consumed',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: const Color.fromARGB(255, 24, 24, 24), fontSize: 12)),
        Text('/ ${goal}g',
            style: TextStyle(color: const Color.fromARGB(255, 73, 73, 73), fontSize: 10)),
      ],
    );
  }
}