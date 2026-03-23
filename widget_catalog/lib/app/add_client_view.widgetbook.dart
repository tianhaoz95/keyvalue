import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:keyvalue_app/screens/add_client_view.dart';
import 'package:keyvalue_app/providers/advisor_provider.dart';
import 'package:keyvalue_app/providers/ui_context_provider.dart';
import 'mocks.dart';

@widgetbook.UseCase(name: 'Default', type: AddClientView)
Widget buildAddClientViewUseCase(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UiContextProvider()),
      ChangeNotifierProvider<AdvisorProvider>(create: (_) => MockAdvisorProvider()),
    ],
    child: const Scaffold(
      body: AddClientView(),
    ),
  );
}
