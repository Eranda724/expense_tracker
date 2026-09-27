import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/categories.dart';
import '../../data/models/expense.dart';
import '../../providers/expense_providers.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final Expense? existingExpense;
  const AddEditExpenseScreen({super.key, this.existingExpense});

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late ExpenseCategory _category;
  late DateTime _date;
  bool _isSaving = false;
  String? _errorText;

  bool get _isEditing => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existingExpense;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toString() : '',
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _category = e?.category ?? ExpenseCategory.food;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _errorText = null);
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(expenseRepositoryProvider);
    if (repo == null) return;

    setState(() => _isSaving = true);
    final amount = double.parse(_amountCtrl.text.trim());

    try {
      if (_isEditing) {
        final updated = widget.existingExpense!.copyWith(
          title: _titleCtrl.text.trim(),
          amount: amount,
          category: _category,
          date: _date,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
        await repo.updateExpense(updated);
      } else {
        final newExpense = Expense(
          id: '',
          title: _titleCtrl.text.trim(),
          amount: amount,
          category: _category,
          date: _date,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          createdAt: DateTime.now(),
        );
        await repo.addExpense(newExpense);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorText = 'Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      case ExpenseCategory.other:
        return Icons.category;
      case ExpenseCategory.health:
        return Icons.favorite;
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildLabel('Title'),
              TextFormField(
                controller: _titleCtrl,
                maxLength: 50,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF166048)),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              _buildLabel('Category'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black26),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ExpenseCategory>(
                          value: _category,
                          isExpanded: true,
                          icon: const Padding(
                            padding: EdgeInsets.only(left: 12.0),
                            child: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black54,
                            ),
                          ),
                          items: ExpenseCategory.values.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                c.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF166048),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForCategory(_category),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              _buildLabel('Date'),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.black54),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM d, yyyy').format(_date),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              _buildLabel('Amount'),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 28, color: Colors.black87),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: r'$ ',
                  prefixStyle: const TextStyle(
                    fontSize: 28,
                    color: Colors.black54,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF166048)),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null) return 'Enter a valid number';
                  if (parsed <= 0) return 'Amount must be greater than 0';
                  if (parsed > 1000000) return 'Amount seems too large';
                  return null;
                },
              ),
              _buildLabel('Note'),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Note (optional)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF166048)),
                  ),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF166048),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update' : 'Save',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
