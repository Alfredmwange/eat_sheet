import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../models/weight_entry.dart';
import '../../providers/user_provider.dart';

class WeightAnalyticsScreen extends StatefulWidget {
  const WeightAnalyticsScreen({super.key});

  @override
  State<WeightAnalyticsScreen> createState() =>
      _WeightAnalyticsScreenState();
}

class _WeightAnalyticsScreenState extends State<WeightAnalyticsScreen> {
  String _selectedRange = '1M';

  List<WeightEntry> _filterEntries(List<WeightEntry> all) {
    final now = DateTime.now();
    final DateTime start;
    switch (_selectedRange) {
      case '3M': start = DateTime(now.year, now.month - 3, now.day); break;
      case '6M': start = DateTime(now.year, now.month - 6, now.day); break;
      case '1Y': start = DateTime(now.year - 1, now.month, now.day);  break;
      default:   start = DateTime(now.year, now.month - 1, now.day);
    }
    return all
        .where((e) => e.date.isAfter(start))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  double _bmi(double weight, double height) {
    if (height <= 0) return 0;
    final h = height / 100;
    return weight / (h * h);
  }

  void _showUpdateWeightSheet(
      BuildContext context, UserProvider provider) {
    final ctrl = TextEditingController();
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Log Today\'s Weight',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'This updates your current weight and adds a point to your chart.',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    suffixText: 'kg',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final w = double.tryParse(ctrl.text);
                              if (w == null || w <= 0) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please enter a valid weight')));
                                return;
                              }
                              setModal(() => saving = true);
                              if (uid != null) {
                                await provider.addWeightEntry(uid, w);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Weight logged: ${w.toStringAsFixed(1)} kg'),
                                  backgroundColor: Colors.green,
                                ));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Text('Save',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final user = provider.user;

        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final allEntries = provider.weightEntries;
        final filtered = _filterEntries(allEntries);
        final bmi = _bmi(user.weight, user.height);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            title: const Text('Analytics',
                style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Summary card ───────────────────────
                _SummaryCard(
                  currentWeight: user.weight,
                  bmi: bmi,
                  goalWeight: user.goalWeight,
                ),
                const SizedBox(height: 16),

                // ── Time range selector ────────────────
                _TimeRangeSelector(
                  selected: _selectedRange,
                  onChanged: (r) => setState(() => _selectedRange = r),
                ),
                const SizedBox(height: 16),

                // ── Chart card ─────────────────────────
                _WeightChartCard(
                  entries: filtered,
                  goalWeight: user.goalWeight,
                  allEntries: allEntries,
                ),
                const SizedBox(height: 20),

                // ── Log weight button ──────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showUpdateWeightSheet(context, provider),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Log Weight',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Summary Card
// ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double currentWeight, bmi, goalWeight;
  const _SummaryCard({
    required this.currentWeight,
    required this.bmi,
    required this.goalWeight,
  });

  String get _bmiCategory {
    if (bmi <= 0)    return '—';
    if (bmi < 18.5)  return 'Underweight';
    if (bmi < 25.0)  return 'Normal';
    if (bmi < 30.0)  return 'Overweight';
    return 'Obese';
  }

  Color get _bmiColor {
    if (bmi <= 0)    return Colors.grey;
    if (bmi < 18.5)  return Colors.blue;
    if (bmi < 25.0)  return Colors.green;
    if (bmi < 30.0)  return Colors.orange;
    return Colors.red;
  }

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
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: _MetricItem(
                  value: '${currentWeight.toStringAsFixed(1)} kg',
                  label: 'Current Weight',
                  color: Colors.blue.shade600)),
          Container(height: 48, width: 1, color: Colors.grey.shade200),
          Expanded(
              child: _MetricItem(
                  value: bmi > 0 ? bmi.toStringAsFixed(1) : '—',
                  label: 'BMI · $_bmiCategory',
                  color: _bmiColor)),
          Container(height: 48, width: 1, color: Colors.grey.shade200),
          Expanded(
              child: _MetricItem(
                  value: goalWeight > 0
                      ? '${goalWeight.toStringAsFixed(1)} kg'
                      : '—',
                  label: 'Goal Weight',
                  color: Colors.orange.shade600)),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MetricItem(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Time Range Selector
// ─────────────────────────────────────────────

class _TimeRangeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _TimeRangeSelector(
      {required this.selected, required this.onChanged});

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
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: ['1M', '3M', '6M', '1Y'].map((r) {
          final sel = selected == r;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? Colors.blue.shade600 : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(r,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.grey.shade600,
                        fontWeight: sel
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Weight Chart Card
// ─────────────────────────────────────────────

class _WeightChartCard extends StatelessWidget {
  final List<WeightEntry> entries;
  final List<WeightEntry> allEntries;
  final double goalWeight;

  const _WeightChartCard({
    required this.entries,
    required this.allEntries,
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weight Progress',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              if (allEntries.isNotEmpty)
                Text('${allEntries.length} entries',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),

          // Legend
          if (goalWeight > 0) ...[
            const SizedBox(height: 10),
            Row(children: [
              _LegendDot(color: Colors.blue.shade600, label: 'Weight'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: Colors.orange.shade400,
                  label: 'Goal (${goalWeight.toStringAsFixed(1)} kg)',
                  dashed: true),
            ]),
          ],

          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: entries.isEmpty
                ? _NoDataWidget(hasAnyData: allEntries.isNotEmpty)
                : _WeightChart(entries: entries, goalWeight: goalWeight),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendDot(
      {required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 20,
        height: 3,
        decoration: BoxDecoration(
          color: dashed ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(2),
          border: dashed
              ? Border.all(color: color, width: 1)
              : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ]);
  }
}

class _NoDataWidget extends StatelessWidget {
  final bool hasAnyData;
  const _NoDataWidget({required this.hasAnyData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_weight_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            hasAnyData
                ? 'No data for this period'
                : 'No weight logged yet',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            hasAnyData
                ? 'Try a longer time range'
                : 'Tap "Log Weight" below to start tracking',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// The actual fl_chart line chart
// ─────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final double goalWeight;

  const _WeightChart(
      {required this.entries, required this.goalWeight});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // Build weight spots — x = index, y = weight
    final spots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
        .toList();

    final weights = entries.map((e) => e.weight).toList();
    final allValues = [...weights, if (goalWeight > 0) goalWeight];

    final minY = allValues.reduce((a, b) => a < b ? a : b) - 2.0;
    final maxY = allValues.reduce((a, b) => a > b ? a : b) + 2.0;

    // Smart x-axis interval — show max 6 labels
    final interval =
        entries.length <= 6 ? 1.0 : (entries.length / 6).ceilToDouble();

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        backgroundColor: Colors.transparent,

        // Grid
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),

        // Border
        borderData: FlBorderData(show: false),

        // Axis bounds
        minX: 0,
        maxX: (entries.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,

        // Titles
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) {
                  return const SizedBox.shrink();
                }
                // Only show on exact interval boundaries
                if (idx % interval.toInt() != 0 &&
                    idx != entries.length - 1) {
                  return const SizedBox.shrink();
                }
                final d = entries[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${d.day}/${d.month}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: (maxY - minY) / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 10),
                );
              },
            ),
          ),
        ),

        // Touch tooltip
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex == 1) {
                  // Goal line
                  return LineTooltipItem(
                    'Goal: ${goalWeight.toStringAsFixed(1)} kg',
                    TextStyle(
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  );
                }
                final idx = spot.x.toInt();
                final entry = entries[idx];
                final d = entry.date;
                return LineTooltipItem(
                  '${entry.weight.toStringAsFixed(1)} kg\n${d.day}/${d.month}/${d.year}',
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                );
              }).toList();
            },
          ),
        ),

        // Lines
        lineBarsData: [
          // Weight line
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: Colors.blue.shade600,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: entries.length <= 10 ? 4 : 2,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: Colors.blue.shade600,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600.withOpacity(0.18),
                  Colors.blue.shade600.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Goal weight dashed line
          if (goalWeight > 0)
            LineChartBarData(
              spots: [
                FlSpot(0, goalWeight),
                FlSpot((entries.length - 1).toDouble(), goalWeight),
              ],
              isCurved: false,
              color: Colors.orange.shade400,
              barWidth: 2,
              isStrokeCapRound: true,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
      ),
    );
  }
}