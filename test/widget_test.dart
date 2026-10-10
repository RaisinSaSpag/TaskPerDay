import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_per_day/main.dart';
import 'package:task_per_day/models/user.dart';
import 'package:task_per_day/screens/settings_screen.dart';

void main() {
  testWidgets('shows Task Per Day splash screen', (tester) async {
    await tester.pumpWidget(const TaskPerDayApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Task Per Day'), findsOneWidget);
    expect(find.text('Make room for what matters.'), findsOneWidget);
  });

  testWidgets('settings tiles build without framework errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          user: AppUser(
            id: 1,
            email: 'student@example.com',
            fullName: 'Test Student',
            createdAt: DateTime(2026),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('About Task Per Day'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
