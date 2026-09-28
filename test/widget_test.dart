import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme has correct primary color', () {
      final theme = AppTheme.light;
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF166048));
    });

    test('dark theme has correct primary color', () {
      final theme = AppTheme.dark;
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFF4ADE80));
    });

    test('dark theme onSurfaceVariant is set for calendar visibility', () {
      final theme = AppTheme.dark;
      expect(theme.colorScheme.onSurfaceVariant, const Color(0xFFE0E0E0));
    });
  });

  group('ProviderScope smoke test', () {
    testWidgets('renders without crashing when wrapped in ProviderScope',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const Scaffold(
              body: Center(child: Text('Wiyaflow')),
            ),
          ),
        ),
      );

      expect(find.text('Wiyaflow'), findsOneWidget);
    });

    testWidgets('dark theme renders correctly in widget tree', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            themeMode: ThemeMode.dark,
            darkTheme: AppTheme.dark,
            home: const Scaffold(
              body: Center(child: Text('Dark Mode')),
            ),
          ),
        ),
      );

      expect(find.text('Dark Mode'), findsOneWidget);
    });
  });
}
