import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:feedback/feedback.dart';
import 'firebase_options.dart';
import 'providers/advisor_provider.dart';
import 'providers/ui_context_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/login_screen.dart';
import 'theme.dart';
import 'models/advisor.dart';
import 'models/customer.dart';
import 'models/engagement.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const bool useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);
  if (useEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }

  // TODO: Set your Stripe publishable key here
  try {
    Stripe.publishableKey = "pk_test_51BTj7pL9q0rG7S4oM6pG0v0v0v0v0v0v0v0"; // 42 characters total
    await Stripe.instance.applySettings();
  } catch (e) {

    debugPrint("Stripe initialization failed: $e");
  }

  await Hive.initFlutter();
  Hive.registerAdapter(AdvisorAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(EngagementStatusAdapter());
  Hive.registerAdapter(EngagementAdapter());
  Hive.registerAdapter(EngagementScheduleAdapter());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UiContextProvider()),
        ChangeNotifierProxyProvider<UiContextProvider, AdvisorProvider>(
          create: (context) => AdvisorProvider(
            uiContext: Provider.of<UiContextProvider>(context, listen: false),
          ),
          update: (context, uiContext, advisorProvider) {
            if (advisorProvider == null) {
              return AdvisorProvider(uiContext: uiContext);
            }
            return advisorProvider..updateUiContext(uiContext);
          },
        ),
        ChangeNotifierProxyProvider2<UiContextProvider, AdvisorProvider, GlobalChatProvider>(
          create: (context) => GlobalChatProvider(
            uiContext: Provider.of<UiContextProvider>(context, listen: false),
            advisorProvider: Provider.of<AdvisorProvider>(context, listen: false),
          ),
          update: (context, uiContext, advisorProvider, chatProvider) {
            if (chatProvider == null) {
              return GlobalChatProvider(uiContext: uiContext, advisorProvider: advisorProvider);
            }
            return chatProvider; // We don't necessarily need to update it every time if it holds its own state, but maybe we want to.
          },
        ),
      ],
      child: Theme(
        data: AppTheme.lightTheme.copyWith(
          inputDecorationTheme: AppTheme.lightTheme.inputDecorationTheme.copyWith(
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black12, width: 1.0),
            ),
          ),
        ),
        child: BetterFeedback(
          theme: FeedbackThemeData(
            background: Colors.grey[200]!,
            feedbackSheetColor: Colors.white,
            activeFeedbackModeColor: Colors.black,
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              secondary: Colors.black,
            ),
            bottomSheetDescriptionStyle: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            dragHandleColor: Colors.black26,
            brightness: Brightness.light,
          ),
          themeMode: ThemeMode.light,
          localizationsDelegates: [
            GlobalFeedbackLocalizationsDelegate(),
          ],
          child: const KeyValueApp(),
        ),
      ),
    ),
  );
}

class KeyValueApp extends StatelessWidget {
  const KeyValueApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdvisorProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KeyValue - Proactive Advisor',
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      locale: provider.locale,
      home: const LoginScreen(),
    );
  }
}
