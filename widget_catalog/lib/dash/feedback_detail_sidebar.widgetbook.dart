import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keyvalue_dash/widgets/feedback_detail_sidebar.dart';
import 'package:keyvalue_dash/models/feedback_item.dart';
import 'package:keyvalue_dash/providers/admin_provider.dart';

class MockAdminProvider extends AdminProvider {
  @override
  Future<void> updateFeedbackStatus(String feedbackId, String status) async {}
  
  @override
  Future<void> deleteFeedback(String feedbackId) async {}
}

@widgetbook.UseCase(name: 'Default', type: FeedbackDetailSidebar)
Widget buildFeedbackDetailSidebarUseCase(BuildContext context) {
  final item = FeedbackItem(
    id: '1',
    advisorUid: 'adv_123',
    advisorName: 'John Doe',
    text: 'This is a test feedback message from the advisor. They are reporting an issue with the profile update flow.',
    createdAt: DateTime.now(),
    screenName: 'CustomerDetailView',
    status: 'open',
  );

  return Scaffold(
    body: Row(
      children: [
        const Expanded(child: Center(child: Text('Main Content'))),
        Container(
          width: 400,
          color: Colors.white,
          child: ChangeNotifierProvider<AdminProvider>(
            create: (_) => MockAdminProvider(),
            child: FeedbackDetailSidebar(
              item: item,
              onClose: () {},
              onDelete: () {},
            ),
          ),
        ),
      ],
    ),
  );
}
