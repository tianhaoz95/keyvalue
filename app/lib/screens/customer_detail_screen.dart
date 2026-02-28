import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/cpa_provider.dart';
import 'engagement_review_screen.dart';
import 'intelligence_hub_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  bool _isEditingProfile = false;
  bool _isEditingGuidelines = false;
  late TextEditingController _profileController;
  late TextEditingController _guidelinesController;

  @override
  void initState() {
    super.initState();
    _profileController = TextEditingController(text: widget.customer.details);
    _guidelinesController = TextEditingController(text: widget.customer.guidelines);
  }

  @override
  void dispose() {
    _profileController.dispose();
    _guidelinesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(CpaProvider provider) async {
    final updatedCustomer = widget.customer.copyWith(details: _profileController.text);
    await provider.addCustomer(updatedCustomer); // addCustomer actually saves/updates in this repo
    setState(() {
      _isEditingProfile = false;
    });
  }

  Future<void> _saveGuidelines(CpaProvider provider) async {
    final updatedCustomer = widget.customer.copyWith(guidelines: _guidelinesController.text);
    await provider.addCustomer(updatedCustomer);
    setState(() {
      _isEditingGuidelines = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CpaProvider>(context);
    // Find the latest version of this customer from provider
    final currentCustomer = provider.customers.firstWhere(
      (c) => c.customerId == widget.customer.customerId,
      orElse: () => widget.customer,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentCustomer.name),
      ),
      body: StreamBuilder<List<Engagement>>(
        stream: provider.getCustomerEngagements(currentCustomer.customerId),
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
                      _buildProfileTab(context, provider, currentCustomer),
                      // Guidelines Tab
                      _buildGuidelinesTab(context, provider, currentCustomer),
                      // History Tab
                      _buildHistoryTab(context, provider, currentCustomer, engagements),
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

  Widget _buildProfileTab(BuildContext context, CpaProvider provider, Customer customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Client Background', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: Icon(_isEditingProfile ? Icons.save : Icons.edit),
                onPressed: () {
                  if (_isEditingProfile) {
                    _saveProfile(provider);
                  } else {
                    setState(() {
                      _isEditingProfile = true;
                      _profileController.text = customer.details;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.grey[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isEditingProfile
                  ? TextField(
                      controller: _profileController,
                      maxLines: null,
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Enter client details...'),
                    )
                  : MarkdownBody(data: customer.details),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelinesTab(BuildContext context, CpaProvider provider, Customer customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Engagement Guidelines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: Icon(_isEditingGuidelines ? Icons.save : Icons.edit),
                onPressed: () {
                  if (_isEditingGuidelines) {
                    _saveGuidelines(provider);
                  } else {
                    setState(() {
                      _isEditingGuidelines = true;
                      _guidelinesController.text = customer.guidelines;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.amber[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber[100]!)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isEditingGuidelines
                  ? TextField(
                      controller: _guidelinesController,
                      maxLines: null,
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Enter engagement guidelines...'),
                    )
                  : MarkdownBody(data: customer.guidelines),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, CpaProvider provider, Customer customer, List<Engagement> engagements) {
    return ListView.separated(
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
                      const Text('Identified Needs / Points of Interest:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                    if (engagement.updatedDetailsDiff.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Profile Updates:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: MarkdownBody(data: engagement.updatedDetailsDiff),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
    } else if (engagement.status == EngagementStatus.received) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact, backgroundColor: Colors.green, foregroundColor: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IntelligenceHubScreen(
                customer: customer,
                engagement: engagement,
              ),
            ),
          );
        },
        child: const Text('Review Update'),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Simulate Customer Response'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Enter client response...'),
              ),
              if (provider.isProcessingResponse)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(width: 16),
                      Text('AI analyzing response...', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: provider.isProcessingResponse ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: provider.isProcessingResponse ? null : () async {
                setDialogState(() {}); // Trigger local rebuild to show progress if needed
                await provider.receiveResponse(customer, engagement, controller.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Process'),
            ),
          ],
        ),
      ),
    );
  }
}
