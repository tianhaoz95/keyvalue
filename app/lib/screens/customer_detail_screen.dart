import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/cpa_provider.dart';
import 'engagement_review_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CpaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit customer details
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Engagement>>(
        stream: provider.getCustomerEngagements(customer.customerId),
        builder: (context, snapshot) {
          final engagements = snapshot.data ?? [];
          final pendingCount = engagements.where((e) => e.status == EngagementStatus.draft).length;

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    const Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
                    const Tab(icon: Icon(Icons.rule), text: 'Guidelines'),
                    Tab(
                      icon: Badge(
                        label: Text('$pendingCount'),
                        isLabelVisible: pendingCount > 0,
                        child: const Icon(Icons.history),
                      ),
                      text: 'History',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Profile Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Client Background', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 0,
                              color: Colors.grey[50],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: MarkdownBody(data: customer.details),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Guidelines Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Engagement Guidelines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 0,
                              color: Colors.amber[50],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber[100]!)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: MarkdownBody(data: customer.guidelines),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // History Tab
                      ListView.separated(
                        itemCount: engagements.length,
                        padding: const EdgeInsets.all(16),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final engagement = engagements[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: engagement.status == EngagementStatus.draft ? Colors.blue[200]! : Colors.grey[300]!,
                              ),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Icon(
                                _getStatusIcon(engagement.status),
                                color: _getStatusColor(engagement.status),
                              ),
                              title: Text(
                                'Engagement: ${engagement.status.name.toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: engagement.status == EngagementStatus.draft ? Colors.blue[700] : Colors.black87,
                                ),
                              ),
                              subtitle: Text('Date: ${engagement.createdAt.toLocal().toString().split('.')[0]}'),
                              trailing: _buildTrailing(context, provider, customer, engagement),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (engagement.draftMessage.isNotEmpty && engagement.status == EngagementStatus.draft)
                                        _buildInfoSection('Suggested Draft:', engagement.draftMessage),
                                      if (engagement.sentMessage.isNotEmpty)
                                        _buildInfoSection('Message Sent:', engagement.sentMessage),
                                      if (engagement.customerResponse.isNotEmpty)
                                        _buildInfoSection('Customer Response:', engagement.customerResponse, isResponse: true),
                                      if (engagement.pointsOfInterest.isNotEmpty) ...[
                                        const Divider(),
                                        const Text('Points of Interest:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                        const SizedBox(height: 8),
                                        ...engagement.pointsOfInterest.map((poi) => Padding(
                                              padding: const EdgeInsets.only(bottom: 4.0),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(Icons.star, size: 16, color: Colors.blue),
                                                  const SizedBox(width: 8),
                                                  Expanded(child: Text(poi)),
                                                ],
                                              ),
                                            )),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, {bool isResponse = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isResponse ? Colors.green[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(content),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  IconData _getStatusIcon(EngagementStatus status) {
    switch (status) {
      case EngagementStatus.draft:
        return Icons.edit_note;
      case EngagementStatus.sent:
        return Icons.send;
      case EngagementStatus.received:
        return Icons.mark_chat_unread;
      case EngagementStatus.completed:
        return Icons.check_circle;
      default:
        return Icons.history;
    }
  }

  Color _getStatusColor(EngagementStatus status) {
    switch (status) {
      case EngagementStatus.draft:
        return Colors.blue;
      case EngagementStatus.sent:
        return Colors.orange;
      case EngagementStatus.received:
        return Colors.green;
      case EngagementStatus.completed:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Widget? _buildTrailing(BuildContext context, CpaProvider provider, Customer customer, Engagement engagement) {
    if (engagement.status == EngagementStatus.draft) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EngagementReviewScreen(
                customer: customer,
                engagement: engagement,
              ),
            ),
          );
        },
        child: const Text('Review'),
      );
    } else if (engagement.status == EngagementStatus.sent) {
      return TextButton.icon(
        icon: const Icon(Icons.add_comment_outlined, size: 18),
        onPressed: () => _showResponseDialog(context, provider, customer, engagement),
        label: const Text('Respond'),
      );
    }
    return null;
  }

  void _showResponseDialog(BuildContext context, CpaProvider provider, Customer customer, Engagement engagement) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate Customer Response'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Enter client response...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await provider.receiveResponse(customer, engagement, controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }
}
