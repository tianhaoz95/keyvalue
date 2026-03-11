import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:keyvalue_app/screens/settings_view.dart';
import 'package:keyvalue_app/providers/advisor_provider.dart';
import 'package:keyvalue_app/providers/ui_context_provider.dart';
import 'package:keyvalue_app/models/advisor.dart';
import 'mocks.dart';

@widgetbook.UseCase(name: 'Default', type: SettingsView)
Widget buildSettingsViewUseCase(BuildContext context) {
  final mockAdvisor = Advisor(
    uid: 'mock_uid',
    name: 'John Advisor',
    firmName: 'Advisor Co.',
    email: 'john@advisor.com',
    cardHolderName: 'John Advisor',
    cardNumber: '4111222233334444',
    expiryDate: '12/26',
    cvv: '123',
    zipCode: '10001',
    subscriptionPlan: 'Pro',
    firmPhoneNumber: '+15551234567',
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UiContextProvider()),
      ChangeNotifierProvider<AdvisorProvider>(create: (_) {
        return MockAdvisorProvider(currentAdvisor: mockAdvisor);
      }),
    ],
    child: Scaffold(
      body: const SettingsView(),
    ),
  );
}
