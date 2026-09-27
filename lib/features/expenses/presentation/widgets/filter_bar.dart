import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/categories.dart';
import '../../data/models/expense.dart';
import '../../providers/expense_providers.dart';

final _kClearSentinel = DateTimeRange(
  start: DateTime(1970),
  end: DateTime(1970),
);

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Future<DateTimeRange?> _showCustomDatePicker(
  BuildContext context, {
  DateTimeRange? initialRange,
}) async {
  return await showDialog<DateTimeRange>(
    context: context,
    builder: (ctx) => _CustomDateRangePickerDialog(initialRange: initialRange),
  );
}

class _CustomDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  const _CustomDateRangePickerDialog({this.initialRange});

  @override
  State<_CustomDateRangePickerDialog> createState() =>
      _CustomDateRangePickerDialogState();
}

class _CustomDateRangePickerDialogState
    extends State<_CustomDateRangePickerDialog> {
  DateTime? _start;
  DateTime? _end;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _start = widget.initialRange!.start;
      _end = widget.initialRange!.end;
      _focusedMonth = DateTime(_start!.year, _start!.month);
    } else {
      final now = DateTime.now();
      _focusedMonth = DateTime(now.year, now.month);
    }
  }

  void _handleTap(DateTime d) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = d;
        _end = null;
      } else {
        if (d.isBefore(_start!)) {
          _start = d;
        } else {
          _end = d;
        }
      }
    });
  }

  bool _isSelected(DateTime d) {
    if (_start != null && _isSameDay(d, _start!)) return true;
    if (_end != null && _isSameDay(d, _end!)) return true;
    if (_start != null && _end != null) {
      return d.isAfter(_start!) && d.isBefore(_end!);
    }
    return false;
  }

  bool _isEndpoint(DateTime d) {
    if (_start != null && _isSameDay(d, _start!)) return true;
    if (_end != null && _isSameDay(d, _end!)) return true;
    return false;
  }

  List<Widget> _buildCalendarDays() {
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final offset = firstDayOfMonth.weekday % 7;
    final List<Widget> cells = [];

    for (int i = 0; i < offset; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int i = 1; i <= daysInMonth; i++) {
      final d = DateTime(_focusedMonth.year, _focusedMonth.month, i);
      final selected = _isSelected(d);
      final endpoint = _isEndpoint(d);

      cells.add(
        GestureDetector(
          onTap: () => _handleTap(d),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: endpoint
                  ? Theme.of(context).colorScheme.primary
                  : selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$i',
                style: TextStyle(
                  color: endpoint
                      ? Theme.of(context).colorScheme.onPrimary
                      : selected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return cells;
  }

  String _selectionLabel() {
    if (_start == null) return 'Select start date';
    if (_end == null) {
      return 'Start: ${DateFormat('MMM d, yyyy').format(_start!)}';
    }
    final s = DateFormat('MMM d').format(_start!);
    final e = DateFormat('MMM d, yyyy').format(_end!);
    if (_isSameDay(_start!, _end!)) return s;
    return '$s - $e';
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_focusedMonth);
    final canSearch = _start != null;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    );
                  }),
                ),
                Text(
                  monthLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    );
                  }),
                ),
              ],
            ),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                  .map(
                    (d) => Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              children: _buildCalendarDays(),
            ),
            const SizedBox(height: 8),
            Text(
              _selectionLabel(),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _kClearSentinel),
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: canSearch
              ? () {
                  final s = DateTime(
                    _start!.year,
                    _start!.month,
                    _start!.day,
                    0,
                    0,
                    0,
                  );
                  final e = (_end != null && !_isSameDay(_start!, _end!))
                      ? DateTime(_end!.year, _end!.month, _end!.day, 23, 59, 59)
                      : DateTime(
                          _start!.year,
                          _start!.month,
                          _start!.day,
                          23,
                          59,
                          59,
                        );
                  Navigator.pop(context, DateTimeRange(start: s, end: e));
                }
              : null,
          child: const Text('Search'),
        ),
      ],
    );
  }
}

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryFilterProvider);
    final dateRange = ref.watch(dateRangeFilterProvider);
    final query = ref.watch(searchQueryProvider);
    final hasActiveFilters =
        category != null || dateRange != null || query.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(
                    color: Colors.black38,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.black38,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              ref.read(searchQueryProvider.notifier).state = '',
                        )
                      : null,
                ),
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ExpenseCategory?>(
                  isExpanded: true,
                  value: category,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.black54,
                  ),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Category', overflow: TextOverflow.ellipsis),
                    ),
                    ...ExpenseCategory.values.map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.label, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      ref.read(categoryFilterProvider.notifier).state = v,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final picked = await _showCustomDatePicker(
                context,
                initialRange: dateRange,
              );
              if (picked == null) return;
              if (picked.start == _kClearSentinel.start &&
                  picked.end == _kClearSentinel.end) {
                ref.read(dateRangeFilterProvider.notifier).state = null;
              } else {
                ref.read(dateRangeFilterProvider.notifier).state = picked;
              }
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateRange == null ? 'Date' : _formatRange(dateRange),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRange(DateTimeRange r) {
    final isSameDay =
        r.start.year == r.end.year &&
        r.start.month == r.end.month &&
        r.start.day == r.end.day;
    if (isSameDay) return DateFormat('MMM d, yyyy').format(r.start);
    return '${DateFormat('MMM d').format(r.start)} - ${DateFormat('MMM d').format(r.end)}';
  }
}
