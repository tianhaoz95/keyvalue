import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:keyvalue_app/widgets/pending_review_list.dart';
import 'package:keyvalue_app/models/customer.dart';
import 'package:keyvalue_app/providers/ui_context_provider.dart';

@widgetbook.UseCase(name: 'Default', type: PendingReviewList)
Widget buildPendingReviewListUseCase(BuildContext context) {
  final List<Customer> mockCustomers = [
    Customer(
      customerId: '1',
      name: 'John Doe',
      email: 'john@example.com',
      occupation: 'Software Engineer',
      details: 'Interested in AI.',
      guidelines: 'Contact via email.',
      engagementFrequencyDays: 30,
      nextEngagementDate: DateTime.now(),
      lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Customer(
      customerId: '2',
      name: 'Jane Smith',
      email: 'jane@example.com',
      occupation: 'Venture Capitalist',
      details: 'Focuses on early-stage startups.',
      guidelines: 'Contact monthly.',
      engagementFrequencyDays: 30,
      nextEngagementDate: DateTime.now(),
      lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  return ChangeNotifierProvider(
    create: (_) => UiContextProvider(),
    child: Scaffold(
      body: Center(
        child: PendingReviewList(customers: mockCustomers),
      ),
    ),
  );
}
