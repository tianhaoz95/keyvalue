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
    await provider.addCustomer(updatedCustomer);
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
    final currentCustomer = provider.customers.firstWhere(
      (c) => c.customerId == widget.customer.customerId,
      orElse: () => widget.customer,
    );

    return LoadingOverlay(
      isLoading: provider.isProcessingResponse || provider.isGeneratingDraft,
      message: provider.isProcessingResponse ? 'AI Analyzing Response...' : 'AI Generating Draft...',
      child: Scaffold(
        appBar: AppBar(
        title: Text(currentCustomer.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (!currentCustomer.hasActiveDraft)
            IconButton(
              onPressed: () => provider.generateManualDraft(currentCustomer),
              icon: const Icon(Icons.auto_awesome_outlined),
              tooltip: 'Generate Draft',
            ),
        ],
      ),
      body: StreamBuilder<List<Engagement>>(
        stream: provider.getCustomerEngagements(currentCustomer.customerId),
        builder: (context, snapshot) {
          final engagements = snapshot.data ?? [];
          final pendingCount = engagements.where((e) => e.status == EngagementStatus.draft).length;

          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Hero(
                        tag: 'avatar_${currentCustomer.customerId}',
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.black,
                          child: Text(
                            currentCustomer.name[0],
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentCustomer.name, 
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)
                            ),
                            Text(
                              currentCustomer.email, 
                              style: const TextStyle(color: Colors.grey, fontSize: 14)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                TabBar(
                  tabs: [
                    const Tab(text: 'PROFILE'),
                    const Tab(text: 'RULES'),
                    Tab(
                      child: Badge(
                        backgroundColor: Colors.black,
                        label: Text('$pendingCount', style: const TextStyle(color: Colors.white)),
                        isLabelVisible: pendingCount > 0,
                        child: const Text('HISTORY'),
                      ),
                    ),
                    const Tab(text: 'SETTINGS'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildProfileTab(context, provider, currentCustomer, engagements),
                      _buildGuidelinesTab(context, provider, currentCustomer),
                      EngagementTimeline(
                        customer: currentCustomer,
                        engagements: engagements,
                        provider: provider,
                        onRespond: (engagement) => _showResponseDialog(context, provider, currentCustomer, engagement),
                      ),
                      _buildSettingsTab(context, provider, currentCustomer),
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
            const SizedBox(height: 40),
          ],
          const Text('CONTACT DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildModernDetailRow(Icons.work_outline, 'Occupation', customer.occupation),
          _buildModernDetailRow(Icons.phone_outlined, 'Phone', customer.phoneNumber),
          _buildModernDetailRow(Icons.location_on_outlined, 'Address', customer.address),
          
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('BACKGROUND', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    tooltip: 'Build Profile with AI',
                    onPressed: () => _showAiGenerationDialog(context, provider, customer),
                  ),
                  IconButton(
                    icon: Icon(_isEditingProfile ? Icons.save : Icons.edit_outlined, size: 18),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: _isEditingProfile
                ? TextField(
                    controller: _profileController,
                    maxLines: null,
                    decoration: const InputDecoration(border: InputBorder.none, filled: false),
                  )
                : MarkdownBody(
                    data: customer.details,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? 'Not provided' : value, 
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)
              ),
            ],
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
              const Text('ENGAGEMENT RULES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    tooltip: 'Build Guidelines with AI',
                    onPressed: () => _showAiGuidelinesDialog(context, provider, customer),
                  ),
                  IconButton(
                    icon: Icon(_isEditingGuidelines ? Icons.save : Icons.edit_outlined, size: 18),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: _isEditingGuidelines
                ? TextField(
                    controller: _guidelinesController,
                    maxLines: null,
                    decoration: const InputDecoration(border: InputBorder.none, filled: false),
                  )
                : MarkdownBody(
                    data: customer.guidelines,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 15, height: 1.6, fontStyle: FontStyle.italic),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context, CpaProvider provider, Customer customer) {
    final nameController = TextEditingController(text: customer.name);
    final emailController = TextEditingController(text: customer.email);
    final occupationController = TextEditingController(text: customer.occupation);
    final phoneController = TextEditingController(text: customer.phoneNumber);
    final addressController = TextEditingController(text: customer.address);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CLIENT SETTINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 16),
          TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 16),
          TextField(controller: occupationController, decoration: const InputDecoration(labelText: 'Occupation')),
          const SizedBox(height: 16),
          TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 16),
          TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final updated = customer.copyWith(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
                occupation: occupationController.text.trim(),
                phoneNumber: phoneController.text.trim(),
                address: addressController.text.trim(),
              );
              await provider.addCustomer(updated);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
              }
            },
            child: const Text('SAVE CHANGES'),
          ),
          const SizedBox(height: 64),
          const Divider(),
          const SizedBox(height: 32),
          const Text('DANGER ZONE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.redAccent)),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
            onPressed: () => _showDeleteConfirmation(context, provider, customer),
            child: const Text('DELETE CLIENT'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CpaProvider provider, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client?'),
        content: Text('Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () async {
              await provider.deleteCustomer(customer.customerId);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${customer.name} removed')));
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightsSection(BuildContext context, CpaProvider provider, Customer customer, Engagement engagement) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_outlined, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI INSIGHTS',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: engagement.pointsOfInterest.map((poi) => Chip(
                    label: Text(poi, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFFF9F9F9),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  )).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROPOSED UPDATE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CURRENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
                              const SizedBox(height: 8),
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
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PROPOSED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white70)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: MarkdownBody(
                                  data: engagement.updatedDetailsDiff,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => provider.dismissResponse(customer, engagement),
                        child: const Text('DISMISS'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => provider.approveResponse(customer, engagement),
                        child: const Text('APPROVE'),
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

  void _showResponseDialog(BuildContext context, CpaProvider provider, Customer customer, Engagement engagement) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Simulate Response'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Enter client response...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                await provider.receiveResponse(customer, engagement, controller.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('PROCESS'),
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
            title: const Text('Build Rules with AI'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: conversation.length + (isAiLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == conversation.length) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          final msg = conversation[index];
                          return Align(
                            alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: msg.isUser ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: msg.isUser ? null : Border.all(color: const Color(0xFFEEEEEE)),
                              ),
                              child: Text(
                                msg.text,
                                style: TextStyle(color: msg.isUser ? Colors.white : Colors.black, fontSize: 13),
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
                      hintText: 'Type message...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
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
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: conversation.length < 2 || isAiLoading ? null : () async {
                  final updated = await provider.finalizeGuidelinesRefinement(customer, conversation);
                  final updatedCustomer = customer.copyWith(guidelines: updated);
                  await provider.addCustomer(updatedCustomer);
                  if (context.mounted) Navigator.pop(context);
                  _guidelinesController.text = updated;
                },
                child: const Text('SAVE RULES'),
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
            title: const Text('Build Profile with AI'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: conversation.length + (isAiLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == conversation.length) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          final msg = conversation[index];
                          return Align(
                            alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: msg.isUser ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: msg.isUser ? null : Border.all(color: const Color(0xFFEEEEEE)),
                              ),
                              child: Text(
                                msg.text,
                                style: TextStyle(color: msg.isUser ? Colors.white : Colors.black, fontSize: 13),
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
                      hintText: 'Type message...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
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
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: conversation.length < 2 || isAiLoading ? null : () async {
                  final updated = await provider.finalizeProfileRefinement(customer, conversation);
                  final updatedCustomer = customer.copyWith(details: updated);
                  await provider.addCustomer(updatedCustomer);
                  if (context.mounted) Navigator.pop(context);
                  _profileController.text = updated;
                },
                child: const Text('SAVE PROFILE'),
              ),
            ],
          );
        },
      ),
    );
  }
}
