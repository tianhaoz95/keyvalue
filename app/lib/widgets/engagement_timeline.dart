import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/cpa_provider.dart';
import '../screens/intelligence_hub_screen.dart';
import '../screens/engagement_review_screen.dart';

class EngagementTimeline extends StatelessWidget {
  final Customer customer;
  final List<Engagement> engagements;
  final CpaProvider provider;
  final Function(Engagement) onRespond;

  const EngagementTimeline({
    super.key,
    required this.customer,
    required this.engagements,
    required this.provider,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    if (engagements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No engagement history yet.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      itemCount: engagements.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final engagement = engagements[index];
        final isLast = index == engagements.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline line and icon
              Column(
                children: [
                  Container(
                    width: 2,
                    height: 16,
                    color: index == 0 ? Colors.transparent : Colors.grey[300],
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getStatusColor(engagement.status).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _getStatusColor(engagement.status), width: 2),
                    ),
                    child: Icon(
                      _getStatusIcon(engagement.status),
                      size: 16,
                      color: _getStatusColor(engagement.status),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : Colors.grey[300],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Content Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getStatusLabel(engagement.status),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(engagement.status),
                                ),
                              ),
                              Text(
                                engagement.createdAt.toLocal().toString().split(' ')[0],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (engagement.sentMessage.isNotEmpty)
                            _buildTimelineSnippet('Message Sent:', engagement.sentMessage),
                          if (engagement.customerResponse.isNotEmpty)
                            _buildTimelineSnippet('Response:', engagement.customerResponse, isAlt: true),
                          if (engagement.status == EngagementStatus.draft)
                            const Text(
                              'A new proactive message is ready for your review.',
                              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                            ),
                          const SizedBox(height: 12),
                          _buildActions(context, engagement),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineSnippet(String label, String text, {bool isAlt = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAlt ? Colors.green[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Engagement engagement) {
    if (engagement.status == EngagementStatus.draft) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(120, 36),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EngagementReviewScreen(customer: customer, engagement: engagement),
            ),
          );
        },
        child: const Text('Review & Send'),
      );
    } else if (engagement.status == EngagementStatus.received) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(120, 36),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IntelligenceHubScreen(customer: customer, engagement: engagement),
            ),
          );
        },
        child: const Text('Review AI Insights'),
      );
    } else if (engagement.status == EngagementStatus.sent) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.reply, size: 16),
        label: const Text('Add Response'),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(120, 36),
        ),
        onPressed: () => onRespond(engagement),
      );
    }
    return const SizedBox.shrink();
  }

  IconData _getStatusIcon(EngagementStatus status) {
    switch (status) {
      case EngagementStatus.draft: return Icons.edit_note;
      case EngagementStatus.sent: return Icons.send;
      case EngagementStatus.received: return Icons.mark_chat_unread;
      case EngagementStatus.completed: return Icons.check_circle;
      default: return Icons.history;
    }
  }

  Color _getStatusColor(EngagementStatus status) {
    switch (status) {
      case EngagementStatus.draft: return Colors.blue;
      case EngagementStatus.sent: return Colors.orange;
      case EngagementStatus.received: return Colors.green;
      case EngagementStatus.completed: return Colors.grey;
      default: return Colors.black;
    }
  }

  String _getStatusLabel(EngagementStatus status) {
    switch (status) {
      case EngagementStatus.draft: return 'PENDING REVIEW';
      case EngagementStatus.sent: return 'OUTBOUND SENT';
      case EngagementStatus.received: return 'INBOUND RESPONSE';
      case EngagementStatus.completed: return 'ARCHIVED';
      default: return 'ENGAGEMENT';
    }
  }
}
