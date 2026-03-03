import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:feedback/feedback.dart';
import 'firebase_options.dart';
import 'providers/advisor_provider.dart';
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

  await Hive.initFlutter();
  Hive.registerAdapter(AdvisorAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(EngagementStatusAdapter());
  Hive.registerAdapter(EngagementAdapter());
  Hive.registerAdapter(EngagementScheduleAdapter());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdvisorProvider()),
      ],
      child: BetterFeedback(
        theme: FeedbackThemeData(
          background: Colors.grey[200]!,
          feedbackSheetColor: Colors.white,
          activeFeedbackModeColor: Colors.black,
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
