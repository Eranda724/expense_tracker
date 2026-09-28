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
              child: _buildBarChart(context, sortedCategories),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: sortedCategories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
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
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForCategory(cat),
                          size: 22,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${percent.toStringAsFixed(1)}% of total',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        NumberFormat.currency(symbol: '\$').format(amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
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
    BuildContext context,
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
    if (normalizedMax <= 1.2) {
      niceMax = 1.0;
    } else if (normalizedMax <= 3.0) {
      niceMax = 2.5;
    } else if (normalizedMax <= 6.0) {
      niceMax = 5.0;
    } else {
      niceMax = 10.0;
    }

    double baseMax = niceMax * magnitude;
    double finalInterval = baseMax / 5;

    double maxY = math.max(baseMax, maxValue * 1.02);

    return Container(
      padding: const EdgeInsets.only(top: 32, right: 24, bottom: 16, left: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface,
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
                  if (value > baseMax) {
                    return const SizedBox.shrink();
                  }
                  if (value == 0) {
                    return Text(
                      '0',
                      style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                    );
                  }
                  return Text(
                    NumberFormat.compactCurrency(symbol: '\$').format(value),
                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
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
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), width: 1.5),
              left: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), width: 1.5),
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
