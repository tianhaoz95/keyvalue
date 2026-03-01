import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/cpa_provider.dart';
import '../services/ai_service.dart';
import '../widgets/engagement_timeline.dart';
import '../widgets/loading_overlay.dart';
import '../l10n/app_localizations.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isEditingProfile = false;
  bool _isEditingGuidelines = false;
  late TextEditingController _profileController;
  late TextEditingController _guidelinesController;

  // AI Side-bar State
  String _aiSidebarMode = 'profile'; // 'profile', 'guidelines', or 'review'
  final List<ChatMessage> _aiConversation = [];
  final TextEditingController _aiInputController = TextEditingController();
  bool _isAiSidebarLoading = false;
  bool _isAiSidebarOpen = false;

  // Review Draft State
  Engagement? _activeReviewEngagement;
  final TextEditingController _reviewDraftController = TextEditingController();

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
    _aiInputController.dispose();
    _reviewDraftController.dispose();
    super.dispose();
  }

  void _openAiSidebar(String mode, CpaProvider provider, Customer customer, {Engagement? engagement}) async {
    // 1. Immediately open sidebar in loading state
    setState(() {
      _aiSidebarMode = mode;
      _aiConversation.clear();
      _activeReviewEngagement = engagement;
      if (mode == 'review' && engagement != null) {
        _reviewDraftController.text = engagement.draftMessage;
      }
      _isAiSidebarLoading = (mode != 'review'); // Don't show typing indicator for review
      _isAiSidebarOpen = true;
    });
    
    // 2. Yield to event loop
    await Future.delayed(Duration.zero);

    if (mode == 'review') return; // No AI response needed for review mode initialization

    final future = mode == 'profile' 
      ? provider.getProfileRefinementResponse(customer, [])
      : provider.getGuidelinesRefinementResponse(customer, []);

    future.then((response) {
      if (mounted) {
        setState(() {
          _aiConversation.add(ChatMessage(text: response, isUser: false));
          _isAiSidebarLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CpaProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final currentCustomer = provider.customers.firstWhere(
      (c) => c.customerId == widget.customer.customerId,
      orElse: () => widget.customer,
    );

    return LoadingOverlay(
      isLoading: provider.isProcessingResponse || provider.isGeneratingDraft,
      message: provider.isProcessingResponse ? 'AI Analyzing Response...' : 'AI Generating Draft...',
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Row(
            children: [
              Hero(
                tag: 'avatar_${currentCustomer.customerId}',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black,
                  child: Text(
                    currentCustomer.name[0],
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentCustomer.name, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)
                    ),
                    Text(
                      currentCustomer.email, 
                      style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.normal)
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (!currentCustomer.hasActiveDraft)
              IconButton(
                onPressed: () => provider.generateManualDraft(currentCustomer),
                icon: const Icon(Icons.auto_awesome_outlined),
                tooltip: 'Generate Draft',
              ),
          ],
        ),
      body: Row(
        children: [
          // Main Content
          Expanded(
            flex: 3,
            child: StreamBuilder<List<Engagement>>(
              stream: provider.getCustomerEngagements(currentCustomer.customerId),
              builder: (context, snapshot) {
                final engagements = snapshot.data ?? [];
                final pendingCount = engagements.where((e) => e.status == EngagementStatus.draft).length;

                return DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(text: l10n.profile.toUpperCase()),
                          const Tab(text: 'RULES'),
                          Tab(
                            child: Badge(
                              backgroundColor: Colors.black,
                              label: Text('$pendingCount', style: const TextStyle(color: Colors.white)),
                              isLabelVisible: pendingCount > 0,
                              child: const Text('HISTORY'),
                            ),
                          ),
                          Tab(text: l10n.settings.toUpperCase()),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildProfileTab(context, provider, currentCustomer, engagements, l10n),
                            _buildGuidelinesTab(context, provider, currentCustomer, l10n),
                            EngagementTimeline(
                              customer: currentCustomer,
                              engagements: engagements,
                              provider: provider,
                              onRespond: (engagement) => _showResponseDialog(context, provider, currentCustomer, engagement),
                              onReviewDraft: (engagement) => _openAiSidebar('review', provider, currentCustomer, engagement: engagement),
                            ),
                            _buildSettingsTab(context, provider, currentCustomer, l10n),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // AI Sidebar (Conditional)
          if (_isAiSidebarOpen)
            const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
          if (_isAiSidebarOpen)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35,
              child: _buildAiSidebarContent(context, provider, currentCustomer, l10n),
            ),
        ],
      ),
    ));
  }

  Widget _buildAiSidebarContent(BuildContext context, CpaProvider provider, Customer customer, AppLocalizations l10n) {
    if (_aiSidebarMode == 'review') {
      return _buildDraftReviewSidebar(context, provider, customer);
    }

    final isProfile = _aiSidebarMode == 'profile';
    
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_outlined, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isProfile ? 'BUILD PROFILE' : 'BUILD RULES',
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isAiSidebarOpen = false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _aiConversation.length + (_isAiSidebarLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _aiConversation.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black12),
                      ),
                    );
                  }
                  final msg = _aiConversation[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _aiInputController,
                    decoration: InputDecoration(
                      hintText: 'Type message...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: _isAiSidebarLoading ? null : () async {
                          final text = _aiInputController.text.trim();
                          if (text.isEmpty) return;
                          _aiInputController.clear();
                          
                          setState(() {
                            _aiConversation.add(ChatMessage(text: text, isUser: true));
                            _isAiSidebarLoading = true;
                          });

                          final response = isProfile
                            ? await provider.getProfileRefinementResponse(customer, _aiConversation)
                            : await provider.getGuidelinesRefinementResponse(customer, _aiConversation);

                          if (mounted) {
                            setState(() {
                              _aiConversation.add(ChatMessage(text: response, isUser: false));
                              _isAiSidebarLoading = false;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _aiConversation.length < 2 || _isAiSidebarLoading ? null : () async {
                      setState(() => _isAiSidebarLoading = true);
                      final updated = isProfile
                        ? await provider.finalizeProfileRefinement(customer, _aiConversation)
                        : await provider.finalizeGuidelinesRefinement(customer, _aiConversation);
                      
                      final updatedCustomer = isProfile
                        ? customer.copyWith(details: updated)
                        : customer.copyWith(guidelines: updated);
                      
                      await provider.addCustomer(updatedCustomer);
                      
                      if (mounted) {
                        setState(() {
                          _isAiSidebarLoading = false;
                          if (isProfile) {
                            _profileController.text = updated;
                          } else {
                            _guidelinesController.text = updated;
                          }
                          _isAiSidebarOpen = false;
                        });
                      }
                    },
                    child: Text(isProfile ? 'SAVE PROFILE' : 'SAVE RULES'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftReviewSidebar(BuildContext context, CpaProvider provider, Customer customer) {
    if (_activeReviewEngagement == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_outlined, size: 24),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'REVIEW DRAFT',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isAiSidebarOpen = false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text('CLIENT CONTEXT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: MarkdownBody(
                            data: customer.details,
                            styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 13, height: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text('ENGAGEMENT RULES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: MarkdownBody(
                            data: customer.guidelines,
                            styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 13, height: 1.5, fontStyle: FontStyle.italic)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('MESSAGE DRAFT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reviewDraftController,
                    maxLines: 15,
                    decoration: InputDecoration(
                      hintText: 'Refine your message...',
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      await provider.sendEngagement(customer, _activeReviewEngagement!, _reviewDraftController.text);
                      if (mounted) {
                        setState(() => _isAiSidebarOpen = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message sent successfully'), backgroundColor: Colors.black),
                          );
                        }
                      }
                    },
                    child: const Text('SEND TO CLIENT'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _reviewDraftController.text));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                          },
                          icon: const Icon(Icons.copy_outlined, size: 16),
                          label: const Text('COPY', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Share.share(_reviewDraftController.text);
                          },
                          icon: const Icon(Icons.share_outlined, size: 16),
                          label: const Text('SHARE', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.black : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: message.isUser ? const Radius.circular(0) : const Radius.circular(12),
            bottomLeft: message.isUser ? const Radius.circular(12) : const Radius.circular(0),
          ),
          border: message.isUser ? null : Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black,
            fontSize: 13,
            height: 1.5
          ),
        ),
      ),
    );
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

  Widget _buildProfileTab(BuildContext context, CpaProvider provider, Customer customer, List<Engagement> engagements, AppLocalizations l10n) {
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
          
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('CONTACT DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              iconColor: Colors.grey,
              collapsedIconColor: Colors.grey,
              children: [
                const SizedBox(height: 16),
                _buildModernDetailRow(Icons.work_outline, 'Occupation', customer.occupation),
                _buildModernDetailRow(Icons.phone_outlined, 'Phone', customer.phoneNumber),
                _buildModernDetailRow(Icons.location_on_outlined, 'Address', customer.address),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.profile.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    tooltip: 'Build Profile with AI',
                    onPressed: () => _openAiSidebar('profile', provider, customer),
                  ),
                  IconButton(
                    icon: Icon(_isEditingProfile ? Icons.check_circle_outline : Icons.edit_outlined, size: 18),
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

  Widget _buildGuidelinesTab(BuildContext context, CpaProvider provider, Customer customer, AppLocalizations l10n) {
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
                    onPressed: () => _openAiSidebar('guidelines', provider, customer),
                  ),
                  IconButton(
                    icon: Icon(_isEditingGuidelines ? Icons.check_circle_outline : Icons.edit_outlined, size: 18),
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
              color: Colors.white,
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

  Widget _buildSettingsTab(BuildContext context, CpaProvider provider, Customer customer, AppLocalizations l10n) {
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
          Text(l10n.account.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
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
            child: Text(l10n.saveChanges.toUpperCase()),
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
            child: Text(l10n.deleteAccount.toUpperCase()),
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
}
