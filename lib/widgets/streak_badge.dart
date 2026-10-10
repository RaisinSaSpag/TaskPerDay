import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({required this.streak, super.key});

  final int streak;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.warning.withValues(alpha: 0.22),
              const Color(0xFFFF5C35).withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded,
                color: AppColors.warning, size: 17),
            const SizedBox(width: 5),
            Text(
              '$streak day${streak == 1 ? '' : 's'}',
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}
