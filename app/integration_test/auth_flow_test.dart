import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:keyvalue_app/providers/cpa_provider.dart';
import 'package:keyvalue_app/repositories/cpa_repository.dart';
import 'package:keyvalue_app/repositories/customer_repository.dart';
import 'package:keyvalue_app/repositories/engagement_repository.dart';
import 'package:keyvalue_app/services/ai_service.dart';
import 'package:keyvalue_app/screens/login_screen.dart';
import 'package:keyvalue_app/screens/dashboard_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full Auth Flow: failed login -> register -> dashboard', (WidgetTester tester) async {
    final auth = MockFirebaseAuth();
    final firestore = FakeFirebaseFirestore();
    
    final cpaRepo = CpaRepository(firestore: firestore);
    final customerRepo = CustomerRepository(firestore: firestore);
    final engagementRepo = EngagementRepository(firestore: firestore);
    final aiService = AiService(isDemo: true); // Use demo mode for tests to avoid FirebaseAI initialization issues

    final provider = CpaProvider(
      cpaRepo: cpaRepo,
      customerRepo: customerRepo,
      engagementRepo: engagementRepo,
      aiService: aiService,
      firebaseAuth: auth,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CpaProvider>.value(value: provider),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LoginScreen), findsOneWidget);

    // 1. Try to sign in with non-existent user
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    
    // Wait for loading to start and finish
    await tester.pump(const Duration(milliseconds: 500));
    // If it's loading, wait more
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump(const Duration(seconds: 1));

    // 2. Register a new account
    final registerButton = find.text('New here? Register a Profile');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.widgetWithText(TextField, 'Email (required)'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password (required)'), 'password123');
    await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Test User');
    await tester.enterText(find.widgetWithText(TextField, 'Firm Name'), 'Test Firm');
    
    final submitButton = find.text('Register & Enter');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    // Wait for registration and navigation
    await tester.pump(const Duration(seconds: 1));
    // Wait for loading in dialog if any
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump(const Duration(seconds: 2));

    // 3. Assert user home page (Dashboard) shows up with correct information
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Test Firm'), findsOneWidget);
    expect(find.text('Welcome, Test User'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
