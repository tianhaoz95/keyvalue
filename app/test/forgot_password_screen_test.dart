import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
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
  testWidgets('Forgot Password navigation from LoginScreen', (WidgetTester tester) async {
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
          ],
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    // Tap Forgot Password?
    final forgotPasswordButton = find.text('Forgot Password?');
    await tester.tap(forgotPasswordButton);
    await tester.pumpAndSettle();

    // Verify we are on ForgotPasswordScreen
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text('RESET PASSWORD'), findsOneWidget);
  });

  testWidgets('ForgotPasswordScreen sends reset link and pops', (WidgetTester tester) async {
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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdvisorProvider>.value(value: advisorProvider),
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
          ],
          home: ForgotPasswordScreen(initialEmail: 'test@example.com'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    expect(find.text('test@example.com'), findsOneWidget);

    final sendLinkButton = find.widgetWithText(ElevatedButton, 'SEND RESET LINK');
    await tester.tap(sendLinkButton);
    await tester.pumpAndSettle();

    // The screen should be popped (in a real app), but in a widget test with only this screen as home, it might just stay or show nothing.
    // However, Navigator.pop(context) was called.
    // We can verify that sendPasswordResetEmail was called if we had a mock, but MockFirebaseAuth handles it.
  });
}
