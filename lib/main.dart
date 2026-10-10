import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/schedule_screen.dart';

import 'app/routes.dart';
import 'app/theme.dart';
import 'models/user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
  try {
    final preferences = await SharedPreferences.getInstance();
    appDarkMode.value = preferences.getBool(AppStrings.darkModeKey) ?? true;
  } catch (error) {
    debugPrint('Could not load theme preference: $error');
  }
  runApp(const TaskPerDayApp());
}

class TaskPerDayApp extends StatelessWidget {
  const TaskPerDayApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: appDarkMode,
        builder: (context, darkMode, _) => MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(darkMode: darkMode),
          home: const SplashScreen(),
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const RegisterScreen(),
          },
          onGenerateRoute: (settings) {
            final user = settings.arguments;
            if (user is! AppUser) {
              return MaterialPageRoute<void>(
                  builder: (_) => const SplashScreen(), settings: settings);
            }
            final Widget screen = switch (settings.name) {
              AppRoutes.home => HomeScreen(user: user),
              AppRoutes.history => HistoryScreen(user: user),
              AppRoutes.schedule => ScheduleScreen(user: user),   // ✨ ADD THIS
              AppRoutes.settings => SettingsScreen(user: user),
              _ => const SplashScreen(),
              };
            return MaterialPageRoute<void>(
              builder: (_) => screen,
              settings: settings,
            );
          },
        ),
      );
}
