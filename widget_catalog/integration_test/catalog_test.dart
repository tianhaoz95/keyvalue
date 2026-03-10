import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:widget_catalog/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Click through all Widgetbook use cases', (WidgetTester tester) async {
    await tester.pumpWidget(const WidgetbookApp());
    await tester.pumpAndSettle();

    // On mobile, the navigation panel might be hidden.
    if (find.text('widgets').evaluate().isEmpty) {
      // Try finding the navigation label specifically
      final navFinder = find.text('Navigation');
      if (navFinder.evaluate().isNotEmpty) {
        await tester.tap(navFinder.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      } else {
        // Maybe try Icons.menu if navigation text is not found
        final menuFinder = find.byIcon(Icons.menu);
        if (menuFinder.evaluate().isNotEmpty) {
           await tester.tap(menuFinder.first, warnIfMissed: false);
           await tester.pumpAndSettle();
        }
      }
    }

    // Use cases and components to click in order to expand/select
    final listToClick = [
      'widgets',
      'ConfirmSlider',
      'Compact',
      'Default', // This is for ConfirmSlider
      'FeedbackDetailSidebar',
      'Default', // This is for FeedbackDetailSidebar
    ];

    for (final name in listToClick) {
      final finder = find.text(name);
      
      // We check if the item is present before tapping
      if (finder.evaluate().isNotEmpty) {
        // We tap and pump to ensure it expands if it's a folder or component.
        await tester.tap(finder.last, warnIfMissed: false);
        await tester.pumpAndSettle();
      }
      
      // Small delay for UI stability
      await tester.pump(const Duration(milliseconds: 200));
    }

    // After clicking everything, make sure we are still on the screen and no error was thrown
    expect(find.byType(WidgetbookApp), findsOneWidget);
  });
}
