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
import 'package:keyvalue_app/screens/settings_view.dart';
import 'package:keyvalue_app/widgets/universal_shell.dart';
import 'package:keyvalue_app/models/advisor.dart';
import 'package:keyvalue_app/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Change Password Flow', (WidgetTester tester) async {
    // Set screen size to desktop
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

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

    // 1. Setup - Register and Login
    final advisor = Advisor(
      uid: '', 
      name: 'Test Advisor', 
      email: 'test@example.com', 
      firmName: 'Test Firm'
    );
    await advisorProvider.register(advisor, 'old_password');
    await advisorProvider.login('test@example.com', 'old_password');

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
          home: UniversalShell(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 2. Open Settings Sidebar
    final settingsIcon = find.byTooltip('Settings');
    expect(settingsIcon, findsWidgets);
    await tester.tap(settingsIcon.first);
    await tester.pumpAndSettle();

    // Verify SettingsView is present
    expect(find.byType(SettingsView), findsOneWidget);

    // 3. Click CHANGE PASSWORD
    final settingsScrollable = find.descendant(
      of: find.byType(SettingsView),
      matching: find.byType(Scrollable),
    );
    expect(settingsScrollable, findsOneWidget);
    final changePwdBtn = find.descendant(
      of: find.byType(SettingsView),
      matching: find.widgetWithText(ElevatedButton, 'CHANGE PASSWORD'),
    );
    await tester.scrollUntilVisible(changePwdBtn, 100, scrollable: settingsScrollable);
    await tester.tap(changePwdBtn);
    await tester.pumpAndSettle();

    // 4. Fill Change Password Dialog
    await tester.enterText(find.widgetWithText(TextFormField, 'Current Password'), 'old_password');
    await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'new_password');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'new_password');
    
    await tester.tap(find.text('UPDATE'));
    await tester.pumpAndSettle();

    // 5. Verify Success Message
    expect(find.text('Password updated successfully!'), findsOneWidget);
    
    // 6. Logout
    final logoutBtn = find.descendant(
      of: find.byType(SettingsView),
      matching: find.widgetWithText(ElevatedButton, 'LOGOUT'),
    );
    await tester.scrollUntilVisible(logoutBtn, 100, scrollable: settingsScrollable);
    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();
    
    expect(find.byType(LoginScreen), findsOneWidget);

    // 7. Login with NEW password (should succeed)
    await tester.enterText(find.widgetWithText(TextField, 'EMAIL'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'PASSWORD'), 'new_password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back, Test'), findsOneWidget);

  }, timeout: const Timeout(Duration(minutes: 5)));
}
