import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

/// Expenses filtered ONLY by the selected Date (ignores category and search).
/// Used by the Summary tab where search/category filters are hidden.
final summaryExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final dateRange = ref.watch(dateRangeFilterProvider);
  final baseAsync = dateRange != null
      ? ref.watch(expensesStreamProvider)
      : ref.watch(monthlyExpensesProvider);

  return baseAsync.whenData((expenses) {
    if (dateRange == null) return expenses;
    return expenses.where((e) {
      final afterStart = !e.date.isBefore(dateRange.start);
      final beforeEnd = !e.date.isAfter(dateRange.end);
      return afterStart && beforeEnd;
    }).toList();
  });
});

/// Sum of amounts for the summary expenses.
final monthlyTotalProvider = Provider<AsyncValue<double>>((ref) {
  final summaryAsync = ref.watch(summaryExpensesProvider);
  return summaryAsync.whenData((expenses) {
    return expenses.fold<double>(0, (total, e) => total + e.amount);
  });
});

/// Category -> total amount, for the summary expenses.
final categorySummaryProvider =
    Provider<AsyncValue<Map<ExpenseCategory, double>>>((ref) {
      final summaryAsync = ref.watch(summaryExpensesProvider);
      return summaryAsync.whenData((expenses) {
        final map = <ExpenseCategory, double>{};
        for (final e in expenses) {
          map[e.category] = (map[e.category] ?? 0) + e.amount;
        }
        return map;
      });
    });

/// null means "all categories" — no filter applied.
final categoryFilterProvider = StateProvider<ExpenseCategory?>((ref) => null);

/// null means "no date range filter" — falls back to month view.
final dateRangeFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Combines month, category filter, date-range filter, and search into one final list.
/// Date range (if set) takes priority over the month selector, since picking an explicit
/// range is a more specific user intent than the default month view.
final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final dateRange = ref.watch(dateRangeFilterProvider);
  final baseAsync = dateRange != null
      ? ref.watch(expensesStreamProvider)
      : ref.watch(monthlyExpensesProvider);
  final category = ref.watch(categoryFilterProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return baseAsync.whenData((expenses) {
    return expenses.where((e) {
      if (dateRange != null) {
        final afterStart = !e.date.isBefore(dateRange.start);
        final beforeEnd = !e.date.isAfter(dateRange.end);
        if (!afterStart || !beforeEnd) return false;
      }
      if (category != null && e.category != category) return false;
      if (query.isNotEmpty) {
        final inTitle = e.title.toLowerCase().contains(query);
        final inNote = (e.note ?? '').toLowerCase().contains(query);
        if (!inTitle && !inNote) return false;
      }
      return true;
    }).toList();
  });
});
