import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/weight_entry.dart';
import '../../providers/user_provider.dart';

class WeightAnalyticsScreen extends StatefulWidget {
  const WeightAnalyticsScreen({super.key});

  @override
  State<WeightAnalyticsScreen> createState() => _WeightAnalyticsScreenState();
}

class _WeightAnalyticsScreenState extends State<WeightAnalyticsScreen> {
  String selectedRange = '1M';

  // Dummy data for now - in real app, this would come from database
  final List<WeightEntry> _allWeightEntries = [
    WeightEntry(
      date: DateTime.now().subtract(const Duration(days: 30)),
      weight: 75.0,
    ),
    WeightEntry(
      date: DateTime.now().subtract(const Duration(days: 25)),
      weight: 74.5,
    ),
    WeightEntry(
      date: DateTime.now().subtract(const Duration(days: 20)),
      weight: 74.0,
    ),
    WeightEntry(
      date: DateTime.now().subtract(const Duration(days: 15)),
      weight: 73.8,
    ),
    WeightEntry(
      date: DateTime.now().subtract(const Duration(days: 10)),
      weight: 73.5,
    ),
    WeightEntry(
      date: DateTime.now().subtract(const Duration(days: 5)),
      weight: 73.2,
    ),
    WeightEntry(date: DateTime.now(), weight: 72.8),
  ];

  List<WeightEntry> getFilteredEntries() {
    final now = DateTime.now();
    DateTime startDate;

    switch (selectedRange) {
      case '1M':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3M':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6M':
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case '1Y':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = DateTime(now.year, now.month - 1, now.day);
    }

    return _allWeightEntries
        .where((entry) => entry.date.isAfter(startDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  double calculateBMI(double weight, double height) {
    if (height <= 0) return 0;
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  void _showUpdateWeightModal() {
    final TextEditingController weightController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Weight',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final weight = double.tryParse(weightController.text);
                        if (weight != null && weight > 0) {
                          // TODO: Save weight entry to database and update user provider
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Weight updated successfully!'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid weight'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B3FE4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currentWeight = user.weight;
        final bmi = calculateBMI(user.weight, user.height);
        final goalWeight = user.goalWeight;
        final filteredEntries = getFilteredEntries();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            title: const Text('Analytics'),
            backgroundColor: Colors.blue.shade600,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary Card
                SummaryCard(
                  currentWeight: currentWeight,
                  bmi: bmi,
                  goalWeight: goalWeight,
                ),
                const SizedBox(height: 20),

                // Time Range Selector
                TimeRangeSelector(
                  selectedRange: selectedRange,
                  onRangeChanged: (range) {
                    setState(() {
                      selectedRange = range;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Weight Progress Card
                WeightProgressCard(weightEntries: filteredEntries),
                const SizedBox(height: 20),

                // Update Weight Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showUpdateWeightModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Update Weight',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SummaryCard extends StatelessWidget {
  final double currentWeight;
  final double bmi;
  final double goalWeight;

  const SummaryCard({
    super.key,
    required this.currentWeight,
    required this.bmi,
    required this.goalWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricItem(
              value: '${currentWeight.toStringAsFixed(1)} kg',
              label: 'Current Weight',
            ),
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade300),
          Expanded(
            child: _MetricItem(value: bmi.toStringAsFixed(1), label: 'BMI'),
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade300),
          Expanded(
            child: _MetricItem(
              value: '${goalWeight.toStringAsFixed(1)} kg',
              label: 'Goal Weight',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String value;
  final String label;

  const _MetricItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 31, 134, 225),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class TimeRangeSelector extends StatelessWidget {
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  const TimeRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: ['1M', '3M', '6M', '1Y'].map((range) {
          final isSelected = selectedRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => onRangeChanged(range),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color.fromARGB(255, 31, 134, 225)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  range,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class WeightProgressCard extends StatelessWidget {
  final List<WeightEntry> weightEntries;

  const WeightProgressCard({super.key, required this.weightEntries});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weight Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: weightEntries.isEmpty
                ? _NoDataWidget()
                : WeightLineChart(weightEntries: weightEntries),
          ),
        ],
      ),
    );
  }
}

class _NoDataWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No weight data yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start tracking your weight to see progress',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class WeightLineChart extends StatelessWidget {
  final List<WeightEntry> weightEntries;

  const WeightLineChart({super.key, required this.weightEntries});

  @override
  Widget build(BuildContext context) {
    final spots = weightEntries
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.weight))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: weightEntries.length > 7 ? weightEntries.length / 7 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < weightEntries.length) {
                  final date = weightEntries[index].date;
                  return Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()} kg',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: spots.isNotEmpty ? spots.length - 1.0 : 0,
        minY: spots.isNotEmpty
            ? spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1
            : 0,
        maxY: spots.isNotEmpty
            ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1
            : 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF7B3FE4),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF7B3FE4).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
