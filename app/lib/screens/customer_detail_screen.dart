import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/cpa_provider.dart';
import '../widgets/engagement_timeline.dart';
import '../widgets/loading_overlay.dart';
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

    return LoadingOverlay(
      isLoading: provider.isProcessingResponse,
      message: 'AI Analyzing Response...',
      child: Scaffold(
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
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'avatar_${currentCustomer.customerId}',
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            currentCustomer.name[0],
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentCustomer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(currentCustomer.email, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: [
                    const Tab(text: 'Profile'),
                    const Tab(text: 'Guidelines'),
                    Tab(
                      child: Badge(
                        label: Text('$pendingCount'),
                        isLabelVisible: pendingCount > 0,
                        child: const Text('History'),
                      ),
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
                      EngagementTimeline(
                        customer: currentCustomer,
                        engagements: engagements,
                        provider: provider,
                        onRespond: (engagement) => _showResponseDialog(context, provider, currentCustomer, engagement),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ));
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
              Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text('Client Background', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: Icon(_isEditingProfile ? Icons.save : Icons.edit),
                color: Theme.of(context).primaryColor,
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
                color: Theme.of(context).primaryColor,
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
            color: Colors.amber.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.amber, width: 0.2)),
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
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
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
