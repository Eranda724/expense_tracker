import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/expense_providers.dart';
import '../widgets/expense_tile.dart';
import 'add_edit_expense_screen.dart';
import '../widgets/month_summary_card.dart';
import '../widgets/filter_bar.dart';
import '../widgets/category_chart.dart';

import '../../../../core/theme/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch filtered async expenses
    final filteredAsync = ref.watch(filteredExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
        bottom: const FilterBar(),
      ),
      body: filteredAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Failed to load expenses.\n$e',
          onRetry: () => ref.invalidate(filteredExpensesProvider),
        ),
        data: (expenses) {
          if (expenses.isEmpty) {
            return Column(
              children: [
                const MonthSummaryCard(),
                const Expanded(
                  child: EmptyView(
                    message: 'No expenses matched your filter.\nOr tap + to add one.',
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              const MonthSummaryCard(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: CategoryChart(),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return ExpenseTile(
                      expense: expense,
                      onTap: () {
                        // navigate to edit screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditExpenseScreen(existingExpense: expense),
                          ),
                        );
                      },
                      onDelete: () {
                        ref
                            .read(expenseRepositoryProvider)
                            ?.deleteExpense(expense.id);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
