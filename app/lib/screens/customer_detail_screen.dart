import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/cpa_provider.dart';
import '../services/ai_service.dart';
import '../widgets/engagement_timeline.dart';
import '../widgets/loading_overlay.dart';

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
      isLoading: provider.isProcessingResponse || provider.isGeneratingDraft,
      message: provider.isProcessingResponse ? 'AI Analyzing Response...' : 'AI Generating Draft...',
      child: Scaffold(
        appBar: AppBar(
        title: Text(currentCustomer.name),
        actions: [
          if (!currentCustomer.hasActiveDraft)
            TextButton.icon(
              onPressed: () => provider.generateManualDraft(currentCustomer),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Draft Check-in'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
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
                      _buildProfileTab(context, provider, currentCustomer, engagements),
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

  Widget _buildProfileTab(BuildContext context, CpaProvider provider, Customer customer, List<Engagement> engagements) {
    final pendingAiEngagement = engagements.cast<Engagement?>().firstWhere(
      (e) => e?.status == EngagementStatus.received,
      orElse: () => null,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingAiEngagement != null) ...[
            _buildAiInsightsSection(context, provider, customer, pendingAiEngagement),
            const SizedBox(height: 32),
          ],
          Row(
            children: [
              Icon(Icons.contact_phone_outlined, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Contact Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(Icons.work_outline, 'Occupation', customer.occupation),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.phone_outlined, 'Phone', customer.phoneNumber),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.location_on, 'Address', customer.address),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    color: Colors.amber[800],
                    tooltip: 'Build Profile with AI',
                    onPressed: () => _showAiGenerationDialog(context, provider, customer),
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

  Widget _buildAiInsightsSection(BuildContext context, CpaProvider provider, Customer customer, Engagement engagement) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'PENDING AI INSIGHTS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: engagement.pointsOfInterest.map((poi) => Chip(
                    label: Text(poi, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  )).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Proposed Profile Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CURRENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Expanded(child: MarkdownBody(data: customer.details)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PROPOSED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                              const SizedBox(height: 4),
                              Expanded(child: MarkdownBody(data: engagement.updatedDetailsDiff)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => provider.dismissResponse(customer, engagement),
                        child: const Text('Keep Current'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => provider.approveResponse(customer, engagement),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value.isEmpty ? 'Not provided' : value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    color: Colors.amber[800],
                    tooltip: 'Build Guidelines with AI',
                    onPressed: () => _showAiGuidelinesDialog(context, provider, customer),
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

  void _showAiGuidelinesDialog(BuildContext context, CpaProvider provider, Customer customer) {
    final List<ChatMessage> conversation = [];
    final controller = TextEditingController();
    bool isAiLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (conversation.isEmpty) {
            isAiLoading = true;
            provider.getGuidelinesRefinementResponse(customer, []).then((response) {
              setDialogState(() {
                conversation.add(ChatMessage(text: response, isUser: false));
                isAiLoading = false;
              });
            });
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber[800], size: 20),
                const SizedBox(width: 8),
                const Text('Build Guidelines with AI'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: conversation.length + (isAiLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == conversation.length) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                            );
                          }
                          final msg = conversation[index];
                          return Align(
                            alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: msg.isUser ? Theme.of(context).primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
                              ),
                              child: Text(
                                msg.text,
                                style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87, fontSize: 13),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Describe engagement rules...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: isAiLoading ? null : () async {
                          if (controller.text.isEmpty) return;
                          final userText = controller.text;
                          controller.clear();
                          setDialogState(() {
                            conversation.add(ChatMessage(text: userText, isUser: true));
                            isAiLoading = true;
                          });
                          
                          final aiResponse = await provider.getGuidelinesRefinementResponse(customer, conversation);
                          setDialogState(() {
                            conversation.add(ChatMessage(text: aiResponse, isUser: false));
                            isAiLoading = false;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: conversation.length < 2 || isAiLoading ? null : () async {
                  setDialogState(() { isAiLoading = true; });
                  final updatedGuidelines = await provider.finalizeGuidelinesRefinement(customer, conversation);
                  final updatedCustomer = customer.copyWith(guidelines: updatedGuidelines);
                  await provider.addCustomer(updatedCustomer);
                  if (context.mounted) Navigator.pop(context);
                  _guidelinesController.text = updatedGuidelines;
                },
                child: const Text('Generate & Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAiGenerationDialog(BuildContext context, CpaProvider provider, Customer customer) {
    final List<ChatMessage> conversation = [];
    final controller = TextEditingController();
    bool isAiLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Initial greeting
          if (conversation.isEmpty) {
            isAiLoading = true;
            provider.getProfileRefinementResponse(customer, []).then((response) {
              setDialogState(() {
                conversation.add(ChatMessage(text: response, isUser: false));
                isAiLoading = false;
              });
            });
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber[800], size: 20),
                const SizedBox(width: 8),
                const Text('Build Profile with AI'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: conversation.length + (isAiLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == conversation.length) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                            );
                          }
                          final msg = conversation[index];
                          return Align(
                            alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: msg.isUser ? Theme.of(context).primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
                              ),
                              child: Text(
                                msg.text,
                                style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87, fontSize: 13),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Describe your client...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: isAiLoading ? null : () async {
                          if (controller.text.isEmpty) return;
                          final userText = controller.text;
                          controller.clear();
                          setDialogState(() {
                            conversation.add(ChatMessage(text: userText, isUser: true));
                            isAiLoading = true;
                          });
                          
                          final aiResponse = await provider.getProfileRefinementResponse(customer, conversation);
                          setDialogState(() {
                            conversation.add(ChatMessage(text: aiResponse, isUser: false));
                            isAiLoading = false;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: conversation.length < 2 || isAiLoading ? null : () async {
                  setDialogState(() { isAiLoading = true; });
                  final updatedDetails = await provider.finalizeProfileRefinement(customer, conversation);
                  final updatedCustomer = customer.copyWith(details: updatedDetails);
                  await provider.addCustomer(updatedCustomer);
                  if (context.mounted) Navigator.pop(context);
                  _profileController.text = updatedDetails;
                },
                child: const Text('Generate & Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
