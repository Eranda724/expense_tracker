import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/categories.dart';
import '../../providers/expense_providers.dart';

// Sentinel range used to signal "user pressed Clear" inside the dialog
final _kClearSentinel = DateTimeRange(
  start: DateTime(1970),
  end: DateTime(1970),
);

Future<DateTimeRange?> _showCustomDatePicker(
  BuildContext context, {
  DateTimeRange? initialRange,
}) async {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (_) => _DatePickerDialog(initial: initialRange),
  );
}

class _DatePickerDialog extends StatefulWidget {
  const _DatePickerDialog({this.initial});
  final DateTimeRange? initial;

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late DateTime _focusedMonth;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _start = widget.initial!.start;
      _end = widget.initial!.end;
      _focusedMonth = DateTime(_start!.year, _start!.month);
    } else {
      final now = DateTime.now();
      _focusedMonth = DateTime(now.year, now.month);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInRange(DateTime d) {
    if (_start == null || _end == null) return false;
    final day = DateTime(d.year, d.month, d.day);
    final s = DateTime(_start!.year, _start!.month, _start!.day);
    final e = DateTime(_end!.year, _end!.month, _end!.day);
    return day.isAfter(s) && day.isBefore(e);
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else {
        if (day.isBefore(_start!)) {
          _end = _start;
          _start = day;
        } else {
          _end = day; // same day or later
        }
      }
    });
  }

  Widget _buildDay(DateTime day, bool inMonth) {
    final isStart = _start != null && _isSameDay(day, _start!);
    final isEnd = _end != null && _isSameDay(day, _end!);
    final inRange = _isInRange(day);
    final today = DateTime.now();
    final isFuture = day.isAfter(DateTime(today.year, today.month, today.day));

    Color? bg;
    Color textColor = inMonth && !isFuture ? Colors.black87 : Colors.black26;
    if (isStart || isEnd) {
      bg = Theme.of(context).colorScheme.primary;
      textColor = Colors.white;
    } else if (inRange) {
      bg = Theme.of(context).colorScheme.primary.withOpacity(0.15);
    }

    return GestureDetector(
      onTap: isFuture || !inMonth ? null : () => _onDayTap(day),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: (isStart || isEnd)
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCalendarDays() {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );
    final startWeekday = firstOfMonth.weekday % 7; // Mon=1..Sun=7 -> 0=Sun

    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) {
      final d = firstOfMonth.subtract(Duration(days: startWeekday - i));
      cells.add(_buildDay(d, false));
    }
    for (int d = 1; d <= lastOfMonth.day; d++) {
      cells.add(
        _buildDay(DateTime(_focusedMonth.year, _focusedMonth.month, d), true),
      );
    }
    while (cells.length % 7 != 0) {
      final d = lastOfMonth.add(
        Duration(days: cells.length - lastOfMonth.day - startWeekday + 1),
      );
      cells.add(_buildDay(d, false));
    }
    return cells;
  }

  String _selectionLabel() {
    if (_start == null) return 'Tap a day to select';
    final fmt = DateFormat('MMM d, yyyy');
    if (_end == null)
      return '${fmt.format(_start!)}  —  tap end date (or Search)';
    if (_isSameDay(_start!, _end!)) return fmt.format(_start!);
    return '${fmt.format(_start!)}  -  ${fmt.format(_end!)}';
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

class FilterBar extends ConsumerWidget implements PreferredSizeWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryFilterProvider);
    final dateRange = ref.watch(dateRangeFilterProvider);
    final query = ref.watch(searchQueryProvider);
    final hasActiveFilters =
        category != null || dateRange != null || query.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by title or note',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          ref.read(searchQueryProvider.notifier).state = '',
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DropdownButton<ExpenseCategory?>(
                  value: category,
                  hint: const Text('Category'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ...ExpenseCategory.values.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                    ),
                  ],
                  onChanged: (v) =>
                      ref.read(categoryFilterProvider.notifier).state = v,
                ),
                const SizedBox(width: 12),
                ActionChip(
                  avatar: Icon(
                    Icons.date_range,
                    size: 18,
                    color: dateRange != null
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  label: Text(
                    dateRange == null ? 'Date range' : _formatRange(dateRange),
                    style: dateRange != null
                        ? TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          )
                        : null,
                  ),
                  onPressed: () async {
                    final picked = await _showCustomDatePicker(
                      context,
                      initialRange: dateRange,
                    );
                    if (picked == null) return; // cancelled
                    if (picked.start == _kClearSentinel.start &&
                        picked.end == _kClearSentinel.end) {
                      // user pressed Clear inside dialog
                      ref.read(dateRangeFilterProvider.notifier).state = null;
                    } else {
                      ref.read(dateRangeFilterProvider.notifier).state = picked;
                    }
                  },
                ),
                if (hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(categoryFilterProvider.notifier).state = null;
                      ref.read(dateRangeFilterProvider.notifier).state = null;
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                    child: const Text('Clear all'),
                  ),
                ],
              ],
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

  @override
  Size get preferredSize => const Size.fromHeight(96);
}
