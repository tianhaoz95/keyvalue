import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:keyvalue_app/screens/login_screen.dart';
import 'package:keyvalue_app/screens/register_screen.dart';
import 'package:keyvalue_app/providers/advisor_provider.dart';
import 'package:keyvalue_app/providers/ui_context_provider.dart';
import 'package:feedback/feedback.dart';
import 'mocks.dart';

@widgetbook.UseCase(name: 'Login Screen', type: LoginScreen)
Widget buildLoginScreenUseCase(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UiContextProvider()),
      ChangeNotifierProvider<AdvisorProvider>(create: (_) => MockAdvisorProvider()),
    ],
    child: BetterFeedback(
      child: const LoginScreen(),
    ),
  );
}

@widgetbook.UseCase(name: 'Register Screen', type: RegisterScreen)
Widget buildRegisterScreenUseCase(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UiContextProvider()),
      ChangeNotifierProvider<AdvisorProvider>(create: (_) => MockAdvisorProvider()),
    ],
    child: BetterFeedback(
      child: const RegisterScreen(),
    ),
  );
}
