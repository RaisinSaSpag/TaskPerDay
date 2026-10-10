import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/database_service.dart';

/// A horizontal 7-day strip showing the current week.
/// - Selected day is highlighted with a gradient pill
/// - Today gets a blue dot
/// - Days with tasks get a small teal dot
/// - Arrows on the left/right navigate between weeks
class DateStrip extends StatefulWidget {
  const DateStrip({
    required this.selectedDate,
    required this.onDateSelected,
    required this.userId,
    super.key,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int userId;

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  late DateTime _weekStart;
  Map<String, int> _taskCounts = {};

  @override
  void initState() {
    super.initState();
    _weekStart = _getMondayOfWeek(widget.selectedDate);
    _loadTaskCounts();
  }

  @override
  void didUpdateWidget(DateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If selected date changed to a different week, re-center
    final newWeekStart = _getMondayOfWeek(widget.selectedDate);
    if (newWeekStart != _weekStart) {
      setState(() => _weekStart = newWeekStart);
    }
    _loadTaskCounts();
  }

  DateTime _getMondayOfWeek(DateTime date) {
    // Weekday: Mon=1 ... Sun=7
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadTaskCounts() async {
    // Get tasks for the visible 7-day week
    try {
      final weekEnd = _weekStart.add(const Duration(days: 6));
      final tasks = await DatabaseService.instance.tasksForDateRange(
        userId: widget.userId,
        start: _weekStart,
        end: weekEnd,
      );

      final counts = <String, int>{};
      for (final task in tasks) {
        final key =
            '${task.date.year}-${task.date.month}-${task.date.day}';
        counts[key] = (counts[key] ?? 0) + 1;
      }

      if (!mounted) return;
      setState(() => _taskCounts = counts);
    } catch (_) {
      // Silent fail — dots just won't show
    }
  }

  void _previousWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
    _loadTaskCounts();
  }

  void _nextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
    _loadTaskCounts();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // ← Previous week
          IconButton(
            onPressed: _previousWeek,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.textSecondary,
            iconSize: 22,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28),
          ),

          // 7 days
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final date = _weekStart.add(Duration(days: index));
                return _buildDay(date, today);
              }),
            ),
          ),

          // → Next week
          IconButton(
            onPressed: _nextWeek,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.textSecondary,
            iconSize: 22,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildDay(DateTime date, DateTime today) {
    final isSelected = _isSameDay(date, widget.selectedDate);
    final isToday = _isSameDay(date, today);
    final key = '${date.year}-${date.month}-${date.day}';
    final hasTasks = (_taskCounts[key] ?? 0) > 0;
    final isPast =
        date.isBefore(DateTime(today.year, today.month, today.day));

    // Colors
    final Color textColor;
    final Color dayNumColor;
    if (isSelected) {
      textColor = Colors.white;
      dayNumColor = Colors.white;
    } else if (isPast) {
      textColor = AppColors.textSecondary.withValues(alpha: 0.5);
      dayNumColor = AppColors.textSecondary.withValues(alpha: 0.5);
    } else {
      textColor = AppColors.textSecondary;
      dayNumColor = AppColors.textPrimary;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onDateSelected(date),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.accentTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.weekdaysShort[date.weekday - 1],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: dayNumColor,
                ),
              ),
              const SizedBox(height: 4),
              // Dot indicators
              SizedBox(
                height: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isToday)
                      _dot(isSelected ? Colors.white : AppColors.accentTeal),
                    if (isToday && hasTasks) const SizedBox(width: 3),
                    if (hasTasks)
                      _dot(isSelected ? Colors.white : AppColors.primaryBlue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}