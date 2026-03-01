import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'providers/cpa_provider.dart';
import 'screens/login_screen.dart';
import 'theme.dart';
import 'models/cpa.dart';
import 'models/customer.dart';
import 'models/engagement.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(CpaAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(EngagementStatusAdapter());
  Hive.registerAdapter(EngagementAdapter());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CpaProvider()),
      ],
      child: const KeyValueApp(),
    ),
  );
}

class KeyValueApp extends StatelessWidget {
  const KeyValueApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CpaProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KeyValue - Proactive CPA',
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
