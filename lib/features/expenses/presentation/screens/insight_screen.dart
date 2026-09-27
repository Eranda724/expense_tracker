import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'dart:math' as math;

import '../../../../core/constants/categories.dart';
import '../../providers/expense_providers.dart';

class InsightTabContent extends ConsumerWidget {
  const InsightTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryData = ref.watch(categorySummaryProvider).value ?? {};
    final totalSpending = ref.watch(monthlyTotalProvider).value ?? 0.0;

    // Sort categories by spending (highest first)
    final sortedCategories = summaryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              height: 250,
              child: _buildBarChart(sortedCategories),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: sortedCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cat = sortedCategories[index].key;
                final amount = sortedCategories[index].value;
                final percent = totalSpending > 0
                    ? (amount / totalSpending) * 100
                    : 0.0;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC2F1DF), // light green
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForCategory(cat),
                          size: 22,
                          color: const Color(0xFF166048),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cat.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0D1512),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${percent.toStringAsFixed(1)}% of total',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        NumberFormat.currency(symbol: '\$').format(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0D1512),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    List<MapEntry<ExpenseCategory, double>> sortedCategories,
  ) {
    if (sortedCategories.isEmpty) {
      return const Center(child: Text('No data for chart'));
    }

    double maxValue = sortedCategories.first.value;
    if (maxValue == 0) maxValue = 100;

    // Find the magnitude of the max value to dynamically set a clean maximum scale
    // We add a small epsilon to handle floating point precision when taking logs
    double magnitude = math
        .pow(10, (math.log(maxValue + 0.0001) / math.ln10).floor())
        .toDouble();
    double normalizedMax = maxValue / magnitude;

    double niceMax;
    // Allow the value to exceed the niceMax by up to 20% before jumping to the next tier.
    // This perfectly handles values like 2550 in the 2500 tier (500 intervals).
    if (normalizedMax <= 1.2) {
      niceMax = 1.0;
    } else if (normalizedMax <= 3.0) {
      niceMax = 2.5;
    } else if (normalizedMax <= 6.0) {
      niceMax = 5.0;
    } else {
      niceMax = 10.0;
    }

    // The base maximum for the grid (e.g., 2500 for the 2.5 tier)
    double baseMax = niceMax * magnitude;
    double finalInterval = baseMax / 5;

    // Set chart's maxY to either the base grid max, or slightly above the maxValue
    // so the highest bar doesn't clip or touch the very top edge.
    double maxY = math.max(baseMax, maxValue * 1.02);

    return Container(
      padding: const EdgeInsets.only(top: 32, right: 24, bottom: 16, left: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 238, 232, 232), // ash color
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < sortedCategories.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      angle: -0.5,
                      child: Text(
                        sortedCategories[value.toInt()].key.label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: finalInterval,
                getTitlesWidget: (value, meta) {
                  // Hide labels for the small padding above the maximum grid line
                  if (value > baseMax) {
                    return const SizedBox.shrink();
                  }
                  if (value == 0) {
                    return const Text(
                      '0',
                      style: TextStyle(fontSize: 10, color: Colors.black54),
                    );
                  }
                  return Text(
                    NumberFormat.compactCurrency(symbol: '\$').format(value),
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: finalInterval,
            getDrawingHorizontalLine: (value) {
              // Hide grid lines for the small padding above the maximum grid line
              if (value > baseMax) {
                return const FlLine(color: Colors.transparent, strokeWidth: 0);
              }
              if (value == 0) {
                return FlLine(
                  color: Colors.grey.withValues(alpha: 0.6),
                  strokeWidth: 1.5,
                );
              }
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: Colors.black54, width: 1.5),
              left: BorderSide(color: Colors.black54, width: 1.5),
              right: BorderSide.none,
              top: BorderSide.none,
            ),
          ),
          barGroups: List.generate(sortedCategories.length, (index) {
            final entry = sortedCategories[index];
            final color = _getColorForCategory(entry.key);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  width: 32,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.5)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Color _getColorForCategory(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.bills:
        return Colors.red;
      case ExpenseCategory.shopping:
        return Colors.purple;
      case ExpenseCategory.health:
        return Colors.green;
      case ExpenseCategory.entertainment:
        return const Color.fromARGB(255, 182, 179, 5);
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  IconData _getIconForCategory(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.bills:
        return Icons.receipt;
      case ExpenseCategory.health:
        return Icons.favorite;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }
}
