import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primaryBlue = Color(0xFF4A90D9);
  static const accentTeal = Color(0xFF2DD4BF);
  static const background = Color(0xFF0A0E1A);
  static const surface = Color(0xFF141824);
  static const card = Color(0xFF1E2433);
  static const border = Color(0xFF2A3142);
  static const textPrimary = Color(0xFFF5F7FA);
  static const textSecondary = Color(0xFF8B92A8);
  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFFB923C);
  static const danger = Color(0xFFF87171);

  // ✨ NEW: Badge colors for future tasks
  static const badgeTomorrow = Color(0xFFFB923C);    // Orange
  static const badgeThisWeek = Color(0xFF60A5FA);    // Light blue
  static const badgeFuture = Color(0xFF8B92A8);      // Gray
}

abstract final class AppStrings {
  static const appName = 'Task Per Day';
  static const maxTasksPerDay = 3;
  static const sessionUserIdKey = 'session_user_id';
  static const darkModeKey = 'dark_mode';
  static const slots = <String>['Morning', 'Afternoon', 'Evening'];

  // ✨ NEW: Date-related strings
  static const weekdaysShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const todayLabel = 'Today';
  static const tomorrowLabel = 'Tomorrow';
  static const yesterdayLabel = 'Yesterday';
  static const missedLabel = 'Missed';
}

abstract final class AppSizes {
  static const pagePadding = 20.0;
  static const cardRadius = 18.0;
}