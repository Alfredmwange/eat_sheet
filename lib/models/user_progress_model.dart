import 'package:eat_sheet/models/food_model.dart';

class UserProgress {
  final String id;
  final String userId;
  final DateTime date;
  final Nutrients dailyIntake;
  final Map<String, double> goalProgress; // percentage achieved for each nutrient
  final DateTime timestamp;

  UserProgress({
    required this.id,
    required this.userId,
    required this.date,
    required this.dailyIntake,
    required this.goalProgress,
    required this.timestamp,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      dailyIntake: Nutrients.fromJson(json['dailyIntake'] ?? {}),
      goalProgress: Map<String, double>.from(json['goalProgress'] ?? {}),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'dailyIntake': dailyIntake.toJson(),
      'goalProgress': goalProgress,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}