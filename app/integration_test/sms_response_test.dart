import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:keyvalue_app/providers/advisor_provider.dart';
import 'package:keyvalue_app/providers/ui_context_provider.dart';
import 'package:keyvalue_app/providers/chat_provider.dart';
import 'package:keyvalue_app/services/ai_service.dart';
import 'package:keyvalue_app/screens/login_screen.dart';
import 'package:keyvalue_app/screens/dashboard_view.dart';
import 'package:keyvalue_app/screens/customer_detail_view.dart';
import 'package:keyvalue_app/widgets/universal_shell.dart';
import 'package:keyvalue_app/models/customer.dart';
import 'package:keyvalue_app/models/advisor.dart';
import 'package:keyvalue_app/models/engagement.dart';
import 'package:keyvalue_app/l10n/app_localizations.dart';
import 'package:keyvalue_app/firebase_options.dart';
import 'package:uuid/uuid.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SMS Response UI Flow: Send SMS -> Wait for Simulated Response -> Show Insights', (WidgetTester tester) async {
    // 1. Initialize real Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    final uiContext = UiContextProvider();
    final advisorProvider = AdvisorProvider(
      uiContext: uiContext,
      aiService: AiService(isDemo: true), // Still use demo AI to avoid cost/latency
    );
    final chatProvider = GlobalChatProvider(
      advisorProvider: advisorProvider,
      uiContext: uiContext,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UiContextProvider>.value(value: uiContext),
          ChangeNotifierProvider<AdvisorProvider>.value(value: advisorProvider),
          ChangeNotifierProvider<GlobalChatProvider>.value(value: chatProvider),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('zh')],
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 2. Register a temporary test user
    final testEmail = 'test_${const Uuid().v4().substring(0, 8)}@example.com';
    final advisorPhone = '408-555-${const Uuid().v4().substring(0, 4)}';
    final clientPhone = '555-999-${const Uuid().v4().substring(0, 4)}';

    print('TEST_DATA: advisorPhone=$advisorPhone clientPhone=$clientPhone');

    await tester.tap(find.text('CREATE AN ACCOUNT'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'EMAIL (REQUIRED)'), testEmail);
    await tester.enterText(find.widgetWithText(TextField, 'PASSWORD (REQUIRED)'), 'password123');
    await tester.enterText(find.widgetWithText(TextField, 'FULL NAME'), 'Test Tester');
    await tester.enterText(find.widgetWithText(TextField, 'BUSINESS NAME'), 'Test Firm');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'CREATE ACCOUNT'));
    
    // Wait for registration and dashboard
    await tester.pump(const Duration(seconds: 2));
    // Wait for any loading indicators to disappear
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.byType(DashboardView).evaluate().isNotEmpty) break;
    }
    
    expect(find.byType(DashboardView), findsOneWidget);
    print('DASHBOARD_LOADED');

    // 3. Set Subscription to Pro and set Advisor Phone
    // Open Settings Sidebar
    final settingsIcon = find.byIcon(Icons.settings_outlined);
    await tester.ensureVisible(settingsIcon);
    await tester.tap(settingsIcon);
    await tester.pumpAndSettle();

    // Change to Pro
    final proPlan = find.text('PRO');
    await tester.ensureVisible(proPlan);
    await tester.tap(proPlan);
    await tester.pumpAndSettle();
    
    // Slide/Click to confirm
    final confirmButton = find.textContaining('CONFIRM PLAN CHANGE');
    if (confirmButton.evaluate().isNotEmpty) {
       await tester.tap(confirmButton);
    } else {
       // Drag the slider if it's mobile view
       final sliderThumb = find.byIcon(Icons.chevron_right);
       await tester.drag(sliderThumb, const Offset(500, 0));
    }
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Advisor phone should be auto-generated now
    final currentAdvisor = advisorProvider.currentAdvisor!;
    final generatedPhone = currentAdvisor.firmPhoneNumber;
    print('TEST_READY_FOR_RESPONSE: advisorPhone=$generatedPhone clientPhone=$clientPhone');

    // Close Settings - look for close icon or just tap outside?
    // In UniversalShell sidebar, there's a close button for non-mobile
    final closeButton = find.byIcon(Icons.close);
    if (closeButton.evaluate().isNotEmpty) {
      await tester.tap(closeButton);
    } else {
      // For mobile view, might need to tap back or similar
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      }
    }
    await tester.pumpAndSettle();

    // 4. Add Customer
    final addIcon = find.byIcon(Icons.add);
    await tester.ensureVisible(addIcon);
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'FULL NAME'), 'Test Client');
    await tester.enterText(find.widgetWithText(TextField, 'PHONE NUMBER'), clientPhone);
    await tester.tap(find.text('SAVE CLIENT'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 5. Send Engagement
    await tester.tap(find.text('Test Client'));
    await tester.pumpAndSettle();

    // Trigger proactive discovery if no draft shows up
    if (find.textContaining('REVIEW DRAFT').evaluate().isEmpty) {
      await advisorProvider.discoverProactiveTasks();
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.textContaining('REVIEW DRAFT').evaluate().isNotEmpty) break;
      }
    }

    // Find the draft in the timeline
    final reviewBtn = find.textContaining('REVIEW DRAFT');
    await tester.ensureVisible(reviewBtn);
    await tester.tap(reviewBtn);
    await tester.pumpAndSettle();
    
    final sendBtn = find.text('SEND MESSAGE');
    await tester.ensureVisible(sendBtn);
    await tester.tap(sendBtn);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 6. Wait for Simulated Response
    print('WAITING_FOR_SIMULATION');
    
    bool received = false;
    for (int i = 0; i < 45; i++) {
      await tester.pump(const Duration(seconds: 2));
      if (find.text('VIEW AI INSIGHTS').evaluate().isNotEmpty) {
        received = true;
        break;
      }
    }

    expect(received, isTrue, reason: 'Timed out waiting for SMS response simulation');

    // 7. Verify Insights UI
    await tester.tap(find.text('VIEW AI INSIGHTS'));
    await tester.pumpAndSettle();
    expect(find.text('PROPOSED PROFILE UPDATE'), findsOneWidget);

    // Cleanup (optional, but good for real Firebase)
    // await advisorProvider.deleteAccount();
  }, timeout: const Timeout(Duration(minutes: 5)));
}
