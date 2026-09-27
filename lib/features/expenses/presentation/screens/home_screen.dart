import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/expense_providers.dart';
import '../widgets/expense_tile.dart';
import 'add_edit_expense_screen.dart';
import '../widgets/month_summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: expensesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Failed to load expenses.\n$e',
          onRetry: () => ref.invalidate(expensesStreamProvider),
        ),
        data: (expenses) {
          if (expenses.isEmpty) {
            return const EmptyView(
              message: 'No expenses yet.\nTap + to add your first one.',
              icon: Icons.receipt_long_outlined,
            );
          }
          return Column(
            children: [
              const MonthSummaryCard(),
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
          // Phase 4: navigate to add screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
