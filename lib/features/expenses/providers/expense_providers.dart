import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';

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
