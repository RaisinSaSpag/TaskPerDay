import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar(
      {required this.currentIndex, required this.onTap, super.key});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.today_outlined, 'Today'),             // index 0
    (Icons.history_outlined, 'History'),         // index 1 ← Fixed
    (Icons.calendar_month_outlined, 'Schedule'), // index 2 ← Fixed
    (Icons.settings_outlined, 'Settings'),       // index 3 ← Fixed
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        minimum: const EdgeInsets.fromLTRB(22, 0, 22, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.97),
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final selected = currentIndex == index;
              final (icon, label) = _items[index];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            color: selected
                                ? AppColors.accentTeal
                                : AppColors.textSecondary,
                            size: 20),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: selected
                                ? AppColors.accentTeal
                                : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
}