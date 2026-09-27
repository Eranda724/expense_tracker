import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/categories.dart';
import '../../data/models/expense.dart';
import '../screens/add_edit_expense_screen.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;

  const ExpenseTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('MMM d').format(expense.date);
    final fmtAmt = NumberFormat.currency(symbol: '\$').format(expense.amount);

    IconData iconData;
    switch (expense.category) {
      case ExpenseCategory.food:
        iconData = Icons.restaurant;
        break;
      case ExpenseCategory.transport:
        iconData = Icons.directions_car;
        break;
      case ExpenseCategory.entertainment:
        iconData = Icons.movie;
        break;
      case ExpenseCategory.shopping:
        iconData = Icons.shopping_bag;
        break;
      case ExpenseCategory.bills:
        iconData = Icons.receipt;
        break;
      case ExpenseCategory.other:
        iconData = Icons.category;
        break;
      case ExpenseCategory.health:
        iconData = Icons.favorite;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditExpenseScreen(existingExpense: expense),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
              child: Icon(iconData, color: const Color(0xFF166048), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (expense.note == null || expense.note!.isEmpty) ? 'Title' : expense.note!,
                    style: const TextStyle(color: Colors.black87, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fmtAmt,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fmtDate,
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
