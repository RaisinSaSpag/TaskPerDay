import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GlassmorphicCard extends StatelessWidget {
  const GlassmorphicCard({
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius = AppSizes.cardRadius,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(borderRadius),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
}
