import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:keyvalue_app/screens/customer_detail_view.dart';
import 'package:keyvalue_app/providers/advisor_provider.dart';
import 'package:keyvalue_app/providers/ui_context_provider.dart';
import 'package:keyvalue_app/models/customer.dart';
import 'package:keyvalue_app/models/advisor.dart';
import 'mocks.dart';

@widgetbook.UseCase(name: 'Full View', type: CustomerDetailView)
Widget buildCustomerDetailViewUseCase(BuildContext context) {
  final mockCustomer = Customer(
    customerId: '1',
    name: 'John Doe',
    email: 'john@doe.com',
    phoneNumber: '+15559876543',
    occupation: 'Software Architect',
    details: 'Likes building scalable systems with Flutter and Go.',
    guidelines: 'Contact every month.',
    address: '123 Tech Lane, Silicon Valley, CA',
    engagementFrequencyDays: 30,
    nextEngagementDate: DateTime.now(),
    lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
  );

  final mockAdvisor = Advisor(
    uid: 'mock_uid',
    name: 'Jane Advisor',
    firmName: 'Wealth Management Inc.',
    email: 'jane@wealth.com',
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UiContextProvider()),
      ChangeNotifierProvider<AdvisorProvider>(create: (_) {
        return MockAdvisorProvider(
          currentAdvisor: mockAdvisor,
          customers: [mockCustomer],
        );
      }),
    ],
    child: Scaffold(
      body: CustomerDetailView(customer: mockCustomer),
    ),
  );
}

@widgetbook.UseCase(name: 'With Proposed Updates', type: CustomerDetailView)
Widget buildCustomerDetailViewWithProposedUpdatesUseCase(BuildContext context) {
  final mockCustomer = Customer(
    customerId: '1',
    name: 'John Doe',
    email: 'john@doe.com',
    phoneNumber: '+15559876543',
    occupation: 'Software Architect',
    details: 'Likes building scalable systems.',
    guidelines: 'Contact every month.',
    engagementFrequencyDays: 30,
    nextEngagementDate: DateTime.now(),
    lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
    proposedDetails: 'Likes building scalable systems and cloud infrastructure.',
    proposedDetailsSummary: 'Added cloud infrastructure interests.',
    proposedGuidelines: 'Contact every two weeks.',
    proposedGuidelinesSummary: 'Increased frequency to bi-weekly.',
  );

  final mockAdvisor = Advisor(
    uid: 'mock_uid',
    name: 'Jane Advisor',
    firmName: 'Wealth Management Inc.',
    email: 'jane@wealth.com',
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UiContextProvider()),
      ChangeNotifierProvider<AdvisorProvider>(create: (_) {
        return MockAdvisorProvider(
          currentAdvisor: mockAdvisor,
          customers: [mockCustomer],
        );
      }),
    ],
    child: Scaffold(
      body: CustomerDetailView(customer: mockCustomer),
    ),
  );
}
