import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/routes.dart';
import '../app/theme.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/gradient_button.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'schedule_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loggingOut = false;
  bool _savingTheme = false;

  Future<void> _toggleTheme(bool enabled) async {
    if (_savingTheme) return;
    setState(() => _savingTheme = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(AppStrings.darkModeKey, enabled);
      appDarkMode.value = enabled;
    } catch (error) {
      debugPrint('Could not save theme preference: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your theme preference.')),
      );
    } finally {
      if (mounted) setState(() => _savingTheme = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (error) {
      debugPrint('Could not log out: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _showInfo(String title, String message) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(title),
          content: Text(message,
              style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ],
        ),
      );

  void _navigate(int index) {
  if (index == 3) return;

  late Widget screen;
  switch (index) {
    case 0:
      screen = HomeScreen(user: widget.user);
      break;
    case 1:
      screen = HistoryScreen(user: widget.user);
      break;
    case 2:
      screen = ScheduleScreen(user: widget.user);
      break;
    default:
      return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => screen),
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Settings',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            Container(
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.18),
                    AppColors.card,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        AppColors.primaryBlue,
                        AppColors.accentTeal
                      ]),
                    ),
                    child: Text(
                      widget.user.fullName.trim().isEmpty
                          ? '?'
                          : widget.user.fullName.trim()[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.user.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(widget.user.email,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const _SectionLabel(label: 'PREFERENCES'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark mode',
              subtitle: 'Keep your focus in the dark',
              trailing: ValueListenableBuilder<bool>(
                valueListenable: appDarkMode,
                builder: (context, darkMode, _) => Switch.adaptive(
                  value: darkMode,
                  onChanged: _savingTheme ? null : _toggleTheme,
                  activeTrackColor: AppColors.accentTeal,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _SectionLabel(label: 'ABOUT'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About Task Per Day',
              subtitle: 'Version 1.0.0',
              onTap: () => _showInfo(
                'Task Per Day',
                'A small, offline-first planner that helps you focus on three meaningful tasks each day.',
              ),
            ),
            const SizedBox(height: 7),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Privacy policy',
              subtitle: 'Your tasks stay on this device',
              onTap: () => _showInfo(
                'Privacy',
                'Your account and planner data are stored locally on this device. No cloud sync is used.',
              ),
            ),
            const SizedBox(height: 30),
            GradientButton(
              label: 'Log Out',
              icon: Icons.logout_rounded,
              onPressed: _logout,
              isLoading: _loggingOut,
            ),
          ],
        ),
        bottomNavigationBar: FloatingNavBar(currentIndex: 3, onTap: _navigate),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(15),
          child: ListTile(
            onTap: onTap,
            leading: Icon(icon, color: AppColors.accentTeal),
            title: Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            trailing: trailing ??
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textSecondary),
          ),
        ),
      );
}
