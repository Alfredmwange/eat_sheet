class WeightEntry {
  final DateTime date;
  final double weight;

  WeightEntry({required this.date, required this.weight});

  // Factory constructor for creating from JSON (if needed for Firestore)
  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      date: DateTime.parse(json['date']),
      weight: json['weight'].toDouble(),
    );
  }

  // Method to convert to JSON (if needed for Firestore)
  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'weight': weight};
  }
}
