import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore;
  final String uid;

  ExpenseRepository(this._firestore, this.uid);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('expenses');

  /// Live stream of all expenses for this user, newest expense date first.
  Stream<List<Expense>> watchExpenses() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Expense.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addExpense(Expense expense) {
    return _collection.add(expense.toMap(includeCreatedAt: true));
  }

  Future<void> updateExpense(Expense expense) {
    return _collection.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) {
    return _collection.doc(expenseId).delete();
  }
}
