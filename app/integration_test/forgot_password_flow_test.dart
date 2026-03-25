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
import 'package:keyvalue_app/screens/forgot_password_screen.dart';
import 'package:keyvalue_app/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Forgot Password Flow: navigate -> send reset link -> success', (WidgetTester tester) async {
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

    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // Enter email in login screen first to see if it carries over
    await tester.enterText(find.widgetWithText(TextField, 'EMAIL'), 'forgot@example.com');
    await tester.pump();

    // Tap Forgot Password?
    final forgotPasswordButton = find.text('Forgot Password?');
    expect(forgotPasswordButton, findsOneWidget);
    await tester.tap(forgotPasswordButton);
    await tester.pumpAndSettle();

    // Verify we are on ForgotPasswordScreen
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text('RESET PASSWORD'), findsOneWidget);

    // Verify email carried over
    final emailField = find.widgetWithText(TextField, 'EMAIL');
    expect(tester.widget<TextField>(emailField).controller?.text, 'forgot@example.com');

    // Tap Send Reset Link
    final sendLinkButton = find.widgetWithText(ElevatedButton, 'SEND RESET LINK');
    await tester.tap(sendLinkButton);
    
    // Wait for process and navigation back
    await tester.pump(); // Start loading
    await tester.pumpAndSettle();

    // Should be back on LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    
    // Verify snackbar (hard to find exact text in tests sometimes, but we can try)
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Password reset link sent to your email.'), findsOneWidget);
  });
}
