import 'dart:async';
import 'package:flutter/material.dart';
import '../app/routes.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  String? _error;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    unawaited(_checkSession());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    try {
      final user = await AuthService.instance.currentUser();
      if (!mounted) return;
      if (user == null) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home,
            arguments: user);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = 'We could not restore your session. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.background,
                Color(0xFF132A4A),
                AppColors.surface
              ],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 94,
                    height: 94,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [
                        AppColors.primaryBlue,
                        AppColors.accentTeal
                      ]),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.28),
                          blurRadius: 32,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Text('3',
                        style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 22),
                  Text(AppStrings.appName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Make room for what matters.',
                      style: TextStyle(color: AppColors.textSecondary)),
                  if (_checking) ...[
                    const SizedBox(height: 26),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentTeal,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _checking = true;
                          _error = null;
                        });
                        unawaited(_checkSession());
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
