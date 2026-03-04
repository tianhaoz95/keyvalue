import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:keyvalue_app/providers/advisor_provider.dart';
import 'package:keyvalue_app/providers/ui_context_provider.dart';
import 'package:keyvalue_app/providers/chat_provider.dart';
import 'package:keyvalue_app/repositories/advisor_repository.dart';
import 'package:keyvalue_app/repositories/customer_repository.dart';
import 'package:keyvalue_app/repositories/engagement_repository.dart';
import 'package:keyvalue_app/services/ai_service.dart';
import 'package:keyvalue_app/screens/login_screen.dart';
import 'package:keyvalue_app/screens/dashboard_view.dart';
import 'package:keyvalue_app/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full Auth Flow: failed login -> register -> dashboard', (WidgetTester tester) async {
    final auth = MockFirebaseAuth();
    final firestore = FakeFirebaseFirestore();
    
    final advisorRepo = AdvisorRepository(firestore: firestore);
    final customerRepo = CustomerRepository(firestore: firestore);
    final engagementRepo = EngagementRepository(firestore: firestore);
    final aiService = AiService(isDemo: true); // Use demo mode for tests to avoid FirebaseAI initialization issues
    final uiContext = UiContextProvider();

    final advisorProvider = AdvisorProvider(
      advisorRepo: advisorRepo,
      customerRepo: customerRepo,
      engagementRepo: engagementRepo,
      aiService: aiService,
      firebaseAuth: auth,
      uiContext: uiContext,
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
          supportedLocales: [
            Locale('en'),
            Locale('zh'),
          ],
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LoginScreen), findsOneWidget);

    // 1. Try to sign in with non-existent user
    await tester.enterText(find.widgetWithText(TextField, 'EMAIL'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'PASSWORD'), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
    
    // Wait for loading to start and finish
    await tester.pump(const Duration(milliseconds: 500));
    // If it's loading, wait more
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump(const Duration(seconds: 1));

    // 2. Register a new account
    final registerButton = find.text('CREATE AN ACCOUNT');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'EMAIL (REQUIRED)'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'PASSWORD (REQUIRED)'), 'password123');
    await tester.enterText(find.widgetWithText(TextField, 'FULL NAME'), 'Test User');
    await tester.enterText(find.widgetWithText(TextField, 'BUSINESS NAME'), 'Test Firm');
    
    // Tap the terms checkbox
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final submitButton = find.widgetWithText(ElevatedButton, 'CREATE ACCOUNT');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    // Wait for registration and navigation
    await tester.pumpAndSettle();
    
    // 3. Assert user home page (Dashboard) shows up with correct information
    expect(find.byType(DashboardView), findsOneWidget);
    expect(find.textContaining('Welcome back, Test'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
