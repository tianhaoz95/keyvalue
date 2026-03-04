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
import 'package:keyvalue_app/screens/customer_detail_view.dart';
import 'package:keyvalue_app/widgets/engagement_timeline.dart';
import 'package:keyvalue_app/widgets/universal_shell.dart';
import 'package:keyvalue_app/models/customer.dart';
import 'package:keyvalue_app/models/advisor.dart';
import 'package:keyvalue_app/models/engagement.dart';
import 'package:keyvalue_app/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full Auth Flow: failed login -> register -> dashboard', (WidgetTester tester) async {
    // ... existing test code ...
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

  testWidgets('AI Insight Interaction: Record Response -> View Insights -> Approve -> Dismiss', (WidgetTester tester) async {
    final auth = MockFirebaseAuth();
    final firestore = FakeFirebaseFirestore();
    
    final advisorRepo = AdvisorRepository(firestore: firestore);
    final customerRepo = CustomerRepository(firestore: firestore);
    final engagementRepo = EngagementRepository(firestore: firestore);
    final aiService = AiService(isDemo: true); 
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

    // Initial setup with a customer
    final testCustomer = Customer(
      customerId: 'cust_123',
      name: 'John Doe',
      email: 'john@example.com',
      occupation: 'Developer',
      details: 'Original details',
      guidelines: 'Original guidelines',
      engagementFrequencyDays: 30,
      nextEngagementDate: DateTime.now(),
      lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
    );
    
    // Mock advisor registration and login
    final advisor = Advisor(
      uid: '', 
      name: 'Test Advisor', 
      email: 'test@example.com', 
      firmName: 'Test Firm'
    );
    await advisorProvider.register(advisor, 'password');
    await advisorProvider.login('test@example.com', 'password', rememberMe: false);
    await advisorProvider.addCustomer(testCustomer);

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
          home: UniversalShell(), // Start with UniversalShell which handles navigation
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    // 1. Navigate to Customer Detail
    await tester.tap(find.text('John Doe'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomerDetailView), findsOneWidget);

    // 2. Add an engagement to record response on
    final engagement = Engagement(
      engagementId: 'eng_1',
      status: EngagementStatus.sent,
      draftMessage: 'Hello',
      sentMessage: 'Hello',
      customerResponse: '',
      pointsOfInterest: [],
      updatedDetailsDiff: '',
      createdAt: DateTime.now(),
    );
    await firestore.collection('advisors').doc(advisorProvider.currentAdvisor!.uid)
        .collection('customers').doc(testCustomer.customerId)
        .collection('engagements').doc(engagement.engagementId).set(engagement.toMap());
    
    await tester.pumpAndSettle();

    // 3. Record Response
    await tester.tap(find.text('ADD RESPONSE')); 
    await tester.pumpAndSettle();
    
    await tester.enterText(find.byType(TextField), 'John is now a Senior Developer at Google.');
    await tester.tap(find.text('PROCESS WITH AI')); 
    
    // Wait for AI processing
    await tester.pump(); // Start loading
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();

    // 4. View AI Insights
    final viewInsightsBtn = find.text('VIEW AI INSIGHTS');
    expect(viewInsightsBtn, findsOneWidget);
    await tester.tap(viewInsightsBtn);
    await tester.pumpAndSettle();

    // 5. Verify "PROPOSED PROFILE UPDATE" shows up
    expect(find.text('PROPOSED PROFILE UPDATE'), findsOneWidget);
    
    // 6. Approve Update
    await tester.tap(find.text('APPROVE UPDATE'));
    // Use short pump to see if it disappears from local state immediately
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // 7. Verify UI disappeared from Timeline
    expect(find.text('PROPOSED PROFILE UPDATE'), findsNothing);
    
    // 8. Test Dismiss as well (need to reset/refresh for a second attempt)
    // We'll add another engagement to test dismiss
    final engagement2 = Engagement(
      engagementId: 'eng_2',
      status: EngagementStatus.sent,
      draftMessage: 'Hello again',
      sentMessage: 'Hello again',
      customerResponse: '',
      pointsOfInterest: [],
      updatedDetailsDiff: '',
      createdAt: DateTime.now(),
    );
    await firestore.collection('advisors').doc(advisorProvider.currentAdvisor!.uid)
        .collection('customers').doc(testCustomer.customerId)
        .collection('engagements').doc(engagement2.engagementId).set(engagement2.toMap());
    
    await tester.pumpAndSettle();

    await tester.tap(find.text('ADD RESPONSE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'John changed his mind.');
    await tester.tap(find.text('PROCESS WITH AI'));
    
    await tester.pump();
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();

    await tester.tap(find.text('VIEW AI INSIGHTS'));
    await tester.pumpAndSettle();
    expect(find.text('PROPOSED PROFILE UPDATE'), findsOneWidget);

    // 9. Dismiss Update
    await tester.tap(find.text('DISMISS'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // 10. Verify UI disappeared
    expect(find.text('PROPOSED PROFILE UPDATE'), findsNothing);
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('Profile Tab AI Interaction: Approve -> Dismiss', (WidgetTester tester) async {
    final auth = MockFirebaseAuth();
    final firestore = FakeFirebaseFirestore();
    
    final advisorRepo = AdvisorRepository(firestore: firestore);
    final customerRepo = CustomerRepository(firestore: firestore);
    final engagementRepo = EngagementRepository(firestore: firestore);
    final aiService = AiService(isDemo: true); 
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

    // Mock advisor registration and login
    final advisor = Advisor(uid: '', name: 'Test Advisor', email: 'test@example.com', firmName: 'Test Firm');
    await advisorProvider.register(advisor, 'password');
    await advisorProvider.login('test@example.com', 'password', rememberMe: false);

    // Initial setup with a customer who has proposed details
    final testCustomer = Customer(
      customerId: 'cust_456',
      name: 'Jane Smith',
      email: 'jane@example.com',
      occupation: 'Designer',
      details: 'Original details',
      proposedDetails: 'Jane is now a Lead Designer.',
      guidelines: 'Original guidelines',
      engagementFrequencyDays: 30,
      nextEngagementDate: DateTime.now(),
      lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
    );
    await advisorProvider.addCustomer(testCustomer);

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
          home: UniversalShell(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    // 1. Navigate to Customer Detail
    await tester.tap(find.text('Jane Smith'));
    await tester.pumpAndSettle();

    // 2. Go to PROFILE tab
    await tester.tap(find.text('PROFILE'));
    await tester.pumpAndSettle();

    // 3. Verify card exists
    expect(find.text('PROPOSED PROFILE UPDATE'), findsOneWidget);
    expect(find.text('APPROVE & UPDATE'), findsOneWidget);

    // 4. Approve
    await tester.tap(find.text('APPROVE & UPDATE'));
    await tester.pumpAndSettle();

    // 5. Verify card gone
    expect(find.text('PROPOSED PROFILE UPDATE'), findsNothing);

    // 6. Set proposed details again to test Dismiss
    final updatedCustomer = testCustomer.copyWith(proposedDetails: 'Some other update.');
    await advisorProvider.addCustomer(updatedCustomer);
    await tester.pumpAndSettle();

    expect(find.text('PROPOSED PROFILE UPDATE'), findsOneWidget);

    // 7. Dismiss
    await tester.tap(find.text('DISMISS'));
    await tester.pumpAndSettle();

    // 8. Verify card gone
    expect(find.text('PROPOSED PROFILE UPDATE'), findsNothing);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
