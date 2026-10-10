import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';


/// A small pill-shaped badge that shows relative time for a future task:
/// - "Tomorrow" (orange)
/// - "In 2 days" (blue)
/// - "Oct 15" (gray)
///
/// Returns an empty widget if the task is for today or in the past.
class DateBadge extends StatelessWidget {
  const DateBadge({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final daysAhead = target.difference(today).inDays;

    // No badge for today or past
    if (daysAhead <= 0) return const SizedBox.shrink();

    // Pick color + label based on how far ahead
    late Color color;
    late String label;

    if (daysAhead == 1) {
      color = AppColors.badgeTomorrow;
      label = AppStrings.tomorrowLabel;
    } else if (daysAhead <= 7) {
      color = AppColors.badgeThisWeek;
      label = 'In $daysAhead days';
    } else {
      color = AppColors.badgeFuture;
      label = DateFormat('MMM d').format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper: check if this date is in the future (after today)
  static bool isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isAfter(today);
  }

  /// Helper: check if this date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Helper: check if this date is in the past
  static bool isPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }
}