import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/admin_provider.dart';
import 'screens/login_screen.dart';
import 'screens/feedback_list_screen.dart';
import 'theme.dart';

// Conditional import for web reload
import 'stub_html.dart' if (dart.library.html) 'dart:html' as html;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    const bool useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);
    if (useEmulator) {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    }

    runApp(const MyApp());
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize app: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'KV Dash',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _tookTooLong = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !Provider.of<AdminProvider>(context, listen: false).isAuthReady) {
        setState(() => _tookTooLong = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    
    if (!provider.isAuthReady) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.black),
              if (_tookTooLong) ...[
                const SizedBox(height: 24),
                const Text('Connecting to services...', style: TextStyle(color: Colors.grey)),
                if (kIsWeb)
                  TextButton(
                    onPressed: () => html.window.location.reload(),
                    child: const Text('RELOAD PAGE'),
                  ),
              ],
            ],
          ),
        ),
      );
    }

    if (provider.user != null) {
      return const FeedbackListScreen();
    } else {
      return const LoginScreen();
    }
  }
}
