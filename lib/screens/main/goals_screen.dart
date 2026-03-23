import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/nutrition_helper.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'add_meal.dart'; 

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // Today's consumed values 
  int _consumedCalories = 0;
  int _consumedProtein  = 0;
  int _consumedCarbs    = 0;
  int _consumedFat      = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayTotals();
  }

  Future<void> _loadTodayTotals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('meal_logs_v1');
    if (raw == null) return;

    final Map<String, dynamic> decoded = jsonDecode(raw);
    int cal = 0, pro = 0, carb = 0, fat = 0;
    decoded.forEach((_, list) {
      for (final e in (list as List)) {
        final entry = FoodEntry.fromJson(e as Map<String, dynamic>);
        cal  += entry.calories;
        pro  += entry.protein;
        carb += entry.carbs;
        fat  += entry.fat;
      }
    });
    if (mounted) {
      setState(() {
        _consumedCalories = cal;
        _consumedProtein  = pro;
        _consumedCarbs    = carb;
        _consumedFat      = fat;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            title: const Text('My Goals',
                style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Recalculate from profile',
                  onPressed: () => _recalculate(context, user, userProvider),
                ),
            ],
          ),
          body: user == null
              ? _NoProfileView()
              : RefreshIndicator(
                  onRefresh: _loadTodayTotals,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GoalSummaryCard(user: user, userProvider: userProvider),
                        const SizedBox(height: 16),
                        _DailyTargetsCard(user: user),
                        const SizedBox(height: 16),
                        _TodayProgressCard(
                          user: user,
                          consumedCalories: _consumedCalories,
                          consumedProtein:  _consumedProtein,
                          consumedCarbs:    _consumedCarbs,
                          consumedFat:      _consumedFat,
                        ),
                        const SizedBox(height: 16),
                        _ChangeGoalCard(
                          user: user,
                          userProvider: userProvider,
                          onGoalChanged: _loadTodayTotals,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _recalculate(
      BuildContext context, User user, UserProvider provider) async {
    if (user.age <= 0 || user.weight <= 0 || user.height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Complete your profile first to recalculate.')));
      return;
    }
    final calories = NutritionHelper.dailyCalorieGoal(
      weightKg: user.weight, heightCm: user.height, age: user.age,
      gender: user.gender, activityLevel: user.activityLevel, goal: user.goal,
    );
    final macros = NutritionHelper.macroGoals(calories);
    final updated = user.copyWith(
      dietaryGoals: {
        'calories': calories.toDouble(),
        'protein':  macros['protein']!.toDouble(),
        'carbs':    macros['carbs']!.toDouble(),
        'fat':      macros['fat']!.toDouble(),
      },
      updatedAt: DateTime.now(),
    );
    await provider.updateUserData(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goals recalculated from your profile.')));
    }
  }
}


// No profile placeholder

class _NoProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_alt_1,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text('No profile found',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 10),
            Text(
              'Complete your profile so we can set personalised nutrition goals for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/complete-profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Complete Profile',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 1. Goal Summary Card

class _GoalSummaryCard extends StatefulWidget {
  final User user;
  final UserProvider userProvider;
  const _GoalSummaryCard({required this.user, required this.userProvider});

  @override
  State<_GoalSummaryCard> createState() => _GoalSummaryCardState();
}

class _GoalSummaryCardState extends State<_GoalSummaryCard> {
  final _goalWeightCtrl = TextEditingController();
  bool _editingGoal = false;
  bool _savingGoal = false;

  @override
  void initState() {
    super.initState();
    _goalWeightCtrl.text = widget.user.goalWeight > 0
        ? widget.user.goalWeight.toStringAsFixed(1)
        : '';
  }

  @override
  void dispose() {
    _goalWeightCtrl.dispose();
    super.dispose();
  }

  double get _bmi {
    if (widget.user.height <= 0) return 0;
    final h = widget.user.height / 100;
    return widget.user.weight / (h * h);
  }

  String get _bmiLabel {
    final b = _bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color get _bmiColor {
    final b = _bmi;
    if (b < 18.5) return Colors.blue;
    if (b < 25.0) return Colors.green;
    if (b < 30.0) return Colors.orange;
    return Colors.red;
  }

  double get _weightProgress {
    final goal = widget.user.goalWeight;
    final current = widget.user.weight;
    if (goal <= 0 || current <= 0) return 0;
    if (current == goal) return 1.0;
    final diff = (current - goal).abs();
    return (1 - (diff / current)).clamp(0.02, 1.0);
  }

  Color get _goalColor {
    switch (widget.user.goal.toLowerCase()) {
      case 'lose_weight': return Colors.orange.shade600;
      case 'gain_weight': return Colors.green.shade600;
      default:            return Colors.blue.shade600;
    }
  }

  Future<void> _saveGoalWeight() async {
    final val = double.tryParse(_goalWeightCtrl.text);
    if (val == null || val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid weight.')));
      return;
    }
    setState(() => _savingGoal = true);
    final updated = widget.user.copyWith(
      goalWeight: val,
      updatedAt: DateTime.now(),
    );
    await widget.userProvider.updateUserData(updated);
    setState(() { _savingGoal = false; _editingGoal = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Goal weight set to ${val.toStringAsFixed(1)} kg'),
        backgroundColor: Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalText = _goalText(widget.user.goal);
    final goalIcon = _goalIcon(widget.user.goal);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Goal type + BMI row ──────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _goalColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(goalIcon, color: _goalColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Goal',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(goalText,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _goalColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _bmiColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  Text(_bmi.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: _bmiColor)),
                  Text('BMI', style: TextStyle(fontSize: 10, color: _bmiColor)),
                  Text(_bmiLabel, style: TextStyle(fontSize: 9, color: _bmiColor)),
                ]),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),

          //  Weight progress bar 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeightStat(
                  label: 'Current',
                  value: '${widget.user.weight.toStringAsFixed(1)} kg',
                  color: Colors.blue.shade600),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _weightProgress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: _goalColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.goalWeight > 0
                          ? '${(widget.user.weight - widget.user.goalWeight).abs().toStringAsFixed(1)} kg to go'
                          : 'No goal set',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ]),
                ),
              ),
              _WeightStat(
                  label: 'Goal',
                  value: widget.user.goalWeight > 0
                      ? '${widget.user.goalWeight.toStringAsFixed(1)} kg'
                      : '—',
                  color: _goalColor),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),

          //Set Goal Weight section 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Set Goal Weight',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F86E1))),
              if (!_editingGoal)
                TextButton.icon(
                  onPressed: () => setState(() => _editingGoal = true),
                  icon: const Icon(Icons.edit, size: 14),
                  label: Text(
                    widget.user.goalWeight > 0 ? 'Edit' : 'Set',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1F86E1),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),

          if (!_editingGoal) ...[
            // Display state
            const SizedBox(height: 8),
            if (widget.user.goalWeight > 0) ...[
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _goalColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _goalColor.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    Icon(Icons.flag_rounded, color: _goalColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.user.goalWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _goalColor),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _goalWeightHint(
                        widget.user.weight, widget.user.goalWeight, widget.user.goal),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500, height: 1.4),
                  ),
                ),
              ]),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text('No goal weight set yet. Tap Set to add one.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ]),
              ),
            ],
          ] else ...[
            // Edit state
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextField(
                  controller: _goalWeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Goal weight (kg)',
                    suffixText: 'kg',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF1F86E1), width: 2)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(children: [
                const SizedBox(height: 4),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _savingGoal ? null : _saveGoalWeight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F86E1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _savingGoal
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _editingGoal = false),
                  child: const Text('Cancel',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ]),
            ]),
          ],
        ],
      ),
    );
  }

  String _goalText(String goal) {
    switch (goal.toLowerCase()) {
      case 'lose_weight': return 'Lose Weight';
      case 'gain_weight': return 'Gain Weight';
      default:            return 'Maintain Weight';
    }
  }

  IconData _goalIcon(String goal) {
    switch (goal.toLowerCase()) {
      case 'lose_weight': return Icons.trending_down;
      case 'gain_weight': return Icons.trending_up;
      default:            return Icons.balance;
    }
  }

  String _goalWeightHint(double current, double goal, String goalType) {
    final diff = (current - goal).abs();
    switch (goalType.toLowerCase()) {
      case 'lose_weight':
        return current > goal
            ? 'Lose ${diff.toStringAsFixed(1)} kg to reach your goal'
            : "You've already reached your goal weight!";
      case 'gain_weight':
        return current < goal
            ? 'Gain ${diff.toStringAsFixed(1)} kg to reach your goal'
            : "You've already reached your goal weight!";
      default:
        return 'Stay within ${diff.toStringAsFixed(1)} kg of your goal';
    }
  }
}

class _WeightStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _WeightStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

// 2. Daily Targets Card

class _DailyTargetsCard extends StatelessWidget {
  final User user;
  const _DailyTargetsCard({required this.user});

  int get _calories =>
      (user.dietaryGoals['calories'] ?? 2000).round();
  int get _protein =>
      (user.dietaryGoals['protein'] ?? 100).round();
  int get _carbs =>
      (user.dietaryGoals['carbs'] ?? 250).round();
  int get _fat =>
      (user.dietaryGoals['fat'] ?? 70).round();

  bool get _hasGoals => user.dietaryGoals.containsKey('calories');

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle('Daily Targets'),
              if (!_hasGoals)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text('Defaults',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Calorie target
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_calories kcal',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const Text('Daily calorie target',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Macro targets row
          Row(
            children: [
              Expanded(
                child: _MacroTargetTile(
                  label: 'Protein',
                  grams: _protein,
                  calories: _protein * 4,
                  percent: 30,
                  color: Colors.green,
                  icon: Icons.egg_alt_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroTargetTile(
                  label: 'Carbs',
                  grams: _carbs,
                  calories: _carbs * 4,
                  percent: 40,
                  color: Colors.orange,
                  icon: Icons.grain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroTargetTile(
                  label: 'Fat',
                  grams: _fat,
                  calories: _fat * 9,
                  percent: 30,
                  color: Colors.red,
                  icon: Icons.opacity,
                ),
              ),
            ],
          ),

          if (_hasGoals) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tap ↺ in the toolbar to recalculate.',
                      style: TextStyle(
                          fontSize: 11, color: const Color.fromARGB(255, 102, 102, 102), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroTargetTile extends StatelessWidget {
  final String label;
  final int grams, calories, percent;
  final Color color;
  final IconData icon;

  const _MacroTargetTile({
    required this.label,
    required this.grams,
    required this.calories,
    required this.percent,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text('${grams}g',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          Text('$calories kcal · $percent%',
              style: TextStyle(fontSize: 10, color: const Color.fromARGB(255, 78, 78, 78))),
        ],
      ),
    );
  }
}

// 3. Today's Progress Card

class _TodayProgressCard extends StatelessWidget {
  final User user;
  final int consumedCalories, consumedProtein, consumedCarbs, consumedFat;

  const _TodayProgressCard({
    required this.user,
    required this.consumedCalories,
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFat,
  });

  int get _calGoal   => (user.dietaryGoals['calories'] ?? 2000).round();
  int get _proGoal   => (user.dietaryGoals['protein']  ?? 100).round();
  int get _carbGoal  => (user.dietaryGoals['carbs']    ?? 250).round();
  int get _fatGoal   => (user.dietaryGoals['fat']      ?? 70).round();

  int get _remaining => (_calGoal - consumedCalories).clamp(0, _calGoal);

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle("Today's Progress"),
          const SizedBox(height: 16),

          // Calorie summary row
          Row(
            children: [
              Expanded(
                child: _CalorieSummaryBox(
                  label: 'Goal',
                  value: _calGoal,
                  color: Colors.blue.shade600,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('−',
                    style:
                        TextStyle(fontSize: 20, color: Color.fromARGB(255, 93, 93, 93))),
              ),
              Expanded(
                child: _CalorieSummaryBox(
                  label: 'Eaten',
                  value: consumedCalories,
                  color: Colors.green.shade600,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('=',
                    style:
                        TextStyle(fontSize: 20, color: Color.fromARGB(255, 65, 65, 65))),
              ),
              Expanded(
                child: _CalorieSummaryBox(
                  label: 'Remaining',
                  value: _remaining,
                  color: _remaining == 0
                      ? Colors.red.shade600
                      : Colors.orange.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Macro progress bars
          _MacroProgressBar(
            label: 'Protein',
            consumed: consumedProtein,
            goal: _proGoal,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _MacroProgressBar(
            label: 'Carbs',
            consumed: consumedCarbs,
            goal: _carbGoal,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _MacroProgressBar(
            label: 'Fat',
            consumed: consumedFat,
            goal: _fatGoal,
            color: Colors.red,
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              '↓ Pull to refresh',
              style: TextStyle(
                  fontSize: 11, color: const Color.fromARGB(255, 76, 76, 76)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieSummaryBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CalorieSummaryBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _MacroProgressBar extends StatelessWidget {
  final String label;
  final int consumed, goal;
  final Color color;
  const _MacroProgressBar({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
  });

  double get _percent =>
      goal > 0 ? (consumed / goal).clamp(0, 1).toDouble() : 0;
  bool get _over => goal > 0 && consumed > goal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text('${consumed}g',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _over ? Colors.red : color)),
                Text(' / ${goal}g',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                if (_over) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: Colors.red.shade400),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _percent,
            minHeight: 10,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(
                _over ? Colors.red.shade400 : color),
          ),
        ),
      ],
    );
  }
}

// 4. Change Goal Card

class _ChangeGoalCard extends StatefulWidget {
  final User user;
  final UserProvider userProvider;
  final VoidCallback onGoalChanged;

  const _ChangeGoalCard({
    required this.user,
    required this.userProvider,
    required this.onGoalChanged,
  });

  @override
  State<_ChangeGoalCard> createState() => _ChangeGoalCardState();
}

class _ChangeGoalCardState extends State<_ChangeGoalCard> {
  late String _selectedGoal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.user.goal;
  }

  Future<void> _save() async {
    if (_selectedGoal == widget.user.goal) return;
    setState(() => _saving = true);

    final calories = NutritionHelper.dailyCalorieGoal(
      weightKg: widget.user.weight,
      heightCm: widget.user.height,
      age: widget.user.age,
      gender: widget.user.gender,
      activityLevel: widget.user.activityLevel,
      goal: _selectedGoal,
    );
    final macros = NutritionHelper.macroGoals(calories);

    final updated = widget.user.copyWith(
      goal: _selectedGoal,
      dietaryGoals: {
        'calories': calories.toDouble(),
        'protein':  macros['protein']!.toDouble(),
        'carbs':    macros['carbs']!.toDouble(),
        'fat':      macros['fat']!.toDouble(),
      },
      updatedAt: DateTime.now(),
    );

    await widget.userProvider.updateUserData(updated);
    setState(() => _saving = false);
    widget.onGoalChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Goal updated to ${_goalLabel(_selectedGoal)}!'),
        backgroundColor: Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = [
      ('lose_weight', 'Lose Weight',    Icons.trending_down, Colors.orange.shade600,
       'Eat 500 kcal below your TDEE'),
      ('maintain',    'Maintain Weight', Icons.balance,       Colors.blue.shade600,
       'Eat at your TDEE'),
      ('gain_weight', 'Gain Weight',     Icons.trending_up,   Colors.green.shade600,
       'Eat 300 kcal above your TDEE'),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Change Goal'),
          const SizedBox(height: 14),

          ...goals.map((g) {
            final (value, label, icon, color, desc) = g;
            final selected = _selectedGoal == value;
            return GestureDetector(
              onTap: () => setState(() => _selectedGoal = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      selected ? color.withOpacity(0.08) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? color : Colors.grey.shade200,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon,
                          color: selected ? color : Colors.grey,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? color
                                      : Colors.black87)),
                          Text(desc,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: const Color.fromARGB(255, 87, 87, 87))),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle,
                          color: color, size: 22),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 6),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedGoal != widget.user.goal && !_saving)
                  ? _save
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Goal',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  String _goalLabel(String goal) {
    switch (goal) {
      case 'lose_weight': return 'Lose Weight';
      case 'gain_weight': return 'Gain Weight';
      default:            return 'Maintain Weight';
    }
  }
}

// Shared layout widgets

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F86E1),
      ),
    );
  }
}