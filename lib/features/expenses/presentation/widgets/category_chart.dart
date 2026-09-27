import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/categories.dart';
import '../../providers/expense_providers.dart';

class CategoryChart extends ConsumerWidget {
  const CategoryChart({super.key});

  // Fixed color per category so the same category always renders the same
  // color across sessions — avoids colors "shuffling" as data changes.
  static const _colors = {
    ExpenseCategory.food: Colors.orange,
    ExpenseCategory.transport: Colors.blue,
    ExpenseCategory.bills: Colors.red,
    ExpenseCategory.shopping: Colors.purple,
    ExpenseCategory.health: Colors.green,
    ExpenseCategory.entertainment: Color.fromARGB(255, 182, 179, 5),
    ExpenseCategory.other: Colors.grey,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categorySummaryProvider);

    return categoryAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (map) {
        if (map.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'No data to chart this month',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final total = map.values.fold<double>(0, (a, b) => a + b);
        final sections = map.entries.map((entry) {
          final percent = (entry.value / total) * 100;
          return PieChartSectionData(
            value: entry.value,
            color: _colors[entry.key],
            title: '${percent.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          );
        }).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 238, 232, 232), // ash color
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 25,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: map.keys.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _colors[cat],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                cat.label,
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
