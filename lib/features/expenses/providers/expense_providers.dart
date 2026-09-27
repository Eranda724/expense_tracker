import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';
import '../../../core/constants/categories.dart';

/// Null when logged out; repository scoped to current uid when logged in.
final expenseRepositoryProvider = Provider<ExpenseRepository?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return null;
  return ExpenseRepository(FirebaseFirestore.instance, user.uid);
});

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchExpenses();
});

/// Currently selected month, stored as the 1st day of that month (year+month matter, day is ignored).
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// All expenses filtered down to the selected month.
final monthlyExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expensesAsync = ref.watch(expensesStreamProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  return expensesAsync.whenData((expenses) {
    return expenses.where((e) {
      return e.date.year == selectedMonth.year &&
          e.date.month == selectedMonth.month;
    }).toList();
  });
});

/// Sum of amounts for the selected month.
final monthlyTotalProvider = Provider<AsyncValue<double>>((ref) {
  final monthlyAsync = ref.watch(monthlyExpensesProvider);
  return monthlyAsync.whenData((expenses) {
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  });
});

/// Category -> total amount, for the selected month.
final categorySummaryProvider =
    Provider<AsyncValue<Map<ExpenseCategory, double>>>((ref) {
      final monthlyAsync = ref.watch(monthlyExpensesProvider);
      return monthlyAsync.whenData((expenses) {
        final map = <ExpenseCategory, double>{};
        for (final e in expenses) {
          map[e.category] = (map[e.category] ?? 0) + e.amount;
        }
        return map;
      });
    });
