import 'package:flutter/material.dart';
import '../models/task.dart';              // ← MUST BE HERE
import '../utils/constants.dart';
import 'date_badge.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.slot,
    required this.task,
    required this.onTap,
    required this.onToggle,
    super.key,
  });

  final String slot;
  final Task? task;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  IconData get _slotIcon => switch (slot) {
        'Morning' => Icons.wb_sunny_outlined,
        'Afternoon' => Icons.wb_cloudy_outlined,
        _ => Icons.nightlight_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final filled = task != null;
    final completed = task?.isCompleted ?? false;
    final isFuture = task != null && DateBadge.isFuture(task!.date);
    final isPast = task != null && DateBadge.isPast(task!.date);
    final isMissed = isPast && !completed;

    // Border color logic
    Color borderColor = AppColors.border;
    if (completed) {
      borderColor = AppColors.success.withValues(alpha: 0.35);
    } else if (isMissed) {
      borderColor = AppColors.danger.withValues(alpha: 0.35);
    } else if (isFuture) {
      borderColor = AppColors.badgeTomorrow.withValues(alpha: 0.35);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: filled ? AppColors.card : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_slotIcon, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          slot,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // ✨ NEW: Date badge for future tasks
                        if (isFuture && !completed) ...[
                          const SizedBox(width: 8),
                          DateBadge(date: task!.date),
                        ],
                        // ✨ NEW: Missed badge for past incomplete
                        if (isMissed) ...[
                          const SizedBox(width: 8),
                          _missedBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      task?.title ?? 'Tap to add your task',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: filled
                            ? (completed
                                ? AppColors.textSecondary
                                : AppColors.textPrimary)
                            : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (filled)
                GestureDetector(
                  onTap: () => onToggle(!completed),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: completed ? AppColors.success : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: completed ? AppColors.success : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: completed
                        ? const Icon(Icons.check, size: 17, color: Colors.black)
                        : null,
                  ),
                )
              else
                const Icon(Icons.add_rounded,
                    color: AppColors.textSecondary, size: 21),
            ],
          ),
        ),
      ),
    );
  }

  Widget _missedBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.4), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 11, color: AppColors.danger),
            SizedBox(width: 4),
            Text(
              'Missed',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
}