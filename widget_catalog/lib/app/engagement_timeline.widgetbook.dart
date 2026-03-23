import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:keyvalue_app/widgets/engagement_timeline.dart';
import 'package:keyvalue_app/models/customer.dart';
import 'package:keyvalue_app/models/engagement.dart';
import 'package:keyvalue_app/providers/advisor_provider.dart';
import 'package:keyvalue_app/providers/ui_context_provider.dart';
import 'mocks.dart';

@widgetbook.UseCase(name: 'Default', type: EngagementTimeline)
Widget buildEngagementTimelineUseCase(BuildContext context) {
  final mockCustomer = Customer(
    customerId: '1',
    name: 'John Doe',
    email: 'john@doe.com',
    details: 'Likes building scalable systems.',
    guidelines: 'Contact every month.',
    engagementFrequencyDays: 30,
    nextEngagementDate: DateTime.now(),
    lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
  );

  final List<Engagement> mockEngagements = [
    Engagement(
      engagementId: '1',
      status: EngagementStatus.received,
      draftMessage: '',
      sentMessage: 'Hi John, how are you?',
      customerResponse: "I am doing well, thanks! Let's talk about the new policy.",
      pointsOfInterest: ['Interested in new policy', 'Doing well'],
      updatedDetailsDiff: 'Interested in new insurance policy.',
      changeSummary: 'Updated interest in insurance.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Engagement(
      engagementId: '2',
      status: EngagementStatus.sent,
      draftMessage: '',
      sentMessage: 'Great, I will send you the details tomorrow.',
      customerResponse: '',
      pointsOfInterest: [],
      updatedDetailsDiff: '',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Engagement(
      engagementId: '3',
      status: EngagementStatus.draft,
      draftMessage: 'Hi John, just following up on our conversation about the new policy. Are you available for a quick call this week?',
      sentMessage: '',
      customerResponse: '',
      pointsOfInterest: [],
      updatedDetailsDiff: '',
      createdAt: DateTime.now(),
    ),
  ];

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UiContextProvider()),
      ChangeNotifierProvider<AdvisorProvider>(create: (_) => MockAdvisorProvider()),
    ],
    child: Scaffold(
      body: EngagementTimeline(
        customer: mockCustomer,
        engagements: mockEngagements,
        provider: MockAdvisorProvider(),
        onRespond: (_) {},
      ),
    ),
  );
}
