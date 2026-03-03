import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:feedback/feedback.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/advisor_provider.dart';
import '../services/ai_service.dart';
import '../services/chat_provider.dart';
import '../widgets/chat_view.dart';
import '../widgets/engagement_timeline.dart';
import '../widgets/loading_overlay.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isEditingProfile = false;
  bool _isEditingRules = false;
  late TextEditingController _profileController;
  late TextEditingController _guidelinesController;

  // AI Side-bar State
  String _aiSidebarMode = 'profile'; // 'profile', 'guidelines', or 'review'
  KeyValueChatProvider? _aiChatProvider;
  bool _isAiSidebarLoading = false;
  bool _isAiSidebarOpen = false;

  // Add Schedule Sidebar State
  bool _isAddScheduleSidebarOpen = false;
  bool _isAddScheduleLoading = false;
  final _addScheduleCadenceController = TextEditingController(text: '1');
  String _addSchedulePeriod = 'months';
  DateTime _addScheduleStartDate = DateTime.now();
  DateTime? _addScheduleEndDate;

  // Review Draft State
  Engagement? _activeReviewEngagement;
  final TextEditingController _reviewDraftController = TextEditingController();
  bool _isRefiningDraft = false;

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
    _reviewDraftController.dispose();
    _addScheduleCadenceController.dispose();
    super.dispose();
  }

  void _openAiSidebar(String mode, AdvisorProvider provider, Customer customer, {Engagement? engagement}) async {
    // 1. Immediately open sidebar in loading state
    setState(() {
      _aiSidebarMode = mode;
      _isRefiningDraft = false;
      _aiChatProvider = KeyValueChatProvider(
        aiService: provider.aiService,
        context: mode == 'profile' 
          ? ChatContext.profile 
          : mode == 'guidelines' 
            ? ChatContext.guidelines 
            : ChatContext.refineDraft,
        advisorProvider: provider,
        customer: customer,
        initialDraft: mode == 'review' ? engagement?.draftMessage : null,
        onConferenceReady: (_) async {
          if (_aiChatProvider == null) return;
          setState(() => _isAiSidebarLoading = true);
          
          String updated;
          if (mode == 'profile') {
            updated = await provider.finalizeProfileRefinement(customer, _aiChatProvider!.history.map((m) => AiChatMessage(
                text: m.text ?? "",
                isUser: m.origin == MessageOrigin.user,
              )).toList());
          } else if (mode == 'guidelines') {
            updated = await provider.finalizeGuidelinesRefinement(customer, _aiChatProvider!.history.map((m) => AiChatMessage(
                text: m.text ?? "",
                isUser: m.origin == MessageOrigin.user,
              )).toList());
          } else {
            updated = await provider.finalizeDraftRefinement(customer, _reviewDraftController.text, _aiChatProvider!.history.map((m) => AiChatMessage(
                text: m.text ?? "",
                isUser: m.origin == MessageOrigin.user,
              )).toList());
          }
          
          if (mounted) {
            setState(() {
              _isAiSidebarLoading = false;
              if (mode == 'profile') {
                _profileController.text = updated;
                _aiChatProvider!.history = [
                  ..._aiChatProvider!.history,
                  ChatMessage(text: "I've prepared the updated profile. You can review and save it now.", origin: MessageOrigin.llm, attachments: const [])
                ];
              } else if (mode == 'guidelines') {
                _guidelinesController.text = updated;
                _aiChatProvider!.history = [
                  ..._aiChatProvider!.history,
                  ChatMessage(text: "I've prepared the updated guidelines. You can review and save them now.", origin: MessageOrigin.llm, attachments: const [])
                ];
              } else {
                _reviewDraftController.text = updated;
                _aiChatProvider!.history = [
                  ..._aiChatProvider!.history,
                  ChatMessage(text: "I've updated the draft for you. You can review it and send it when ready.", origin: MessageOrigin.llm, attachments: const [])
                ];
              }
            });
          }
        },
      );
      _activeReviewEngagement = engagement;
      if (mode == 'review' && engagement != null) {
        _reviewDraftController.text = engagement.draftMessage;
      }
      _isAiSidebarLoading = true;
      _isAiSidebarOpen = true;
    });
    
    // 2. Yield to event loop
    await Future.delayed(Duration.zero);

    final future = mode == 'profile' 
      ? provider.getProfileRefinementResponse(customer, [])
      : mode == 'guidelines'
        ? provider.getGuidelinesRefinementResponse(customer, [])
        : provider.getDraftRefinementResponse(customer, _reviewDraftController.text, []);

    future.then((response) {
      if (mounted && _aiChatProvider != null) {
        setState(() {
          _aiChatProvider!.history = [
            ChatMessage(
              text: response,
              origin: MessageOrigin.llm,
              attachments: const [],
            )
          ];
          _isAiSidebarLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdvisorProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final currentCustomer = provider.customers.firstWhere(
      (c) => c.customerId == widget.customer.customerId,
      orElse: () => widget.customer,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;
    final sidebarWidth = isPhone ? screenWidth : screenWidth * 0.35;
    final isAnySidebarOpen = _isAiSidebarOpen || _isAddScheduleSidebarOpen;

    return LoadingOverlay(
      isLoading: provider.isProcessingResponse || provider.isGeneratingDraft,
      message: provider.isProcessingResponse ? 'AI Analyzing Response...' : 'AI Generating Draft...',
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Image.asset(
                    'assets/images/logo_120.png', 
                    height: 24,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const SizedBox(
                height: 20,
                child: VerticalDivider(width: 1, thickness: 1, color: Colors.black12),
              ),
              const SizedBox(width: 16),
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
            IconButton(
              onPressed: () => provider.generateManualDraft(currentCustomer),
              icon: const Icon(Icons.auto_awesome_outlined),
              tooltip: 'Generate Draft',
            ),
            IconButton(
              icon: const Icon(Icons.feedback_outlined),
              tooltip: 'Send Feedback',
              onPressed: () {
                BetterFeedback.of(context).show((feedback) {
                  debugPrint('Feedback text: ${feedback.text}');
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            // Main Content
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
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
                                dividerColor: Colors.transparent,
                                tabs: [
                                  Tab(
                                    icon: Badge(
                                      backgroundColor: Colors.black,
                                      label: Text('$pendingCount', style: const TextStyle(color: Colors.white)),
                                      isLabelVisible: pendingCount > 0,
                                      child: const Icon(Icons.history),
                                    ),
                                    text: isPhone ? null : l10n.engagement.toUpperCase(),
                                  ),
                                  Tab(
                                    icon: const Icon(Icons.person_outline),
                                    text: isPhone ? null : l10n.profile.toUpperCase(),
                                  ),
                                  Tab(
                                    icon: const Icon(Icons.rule_outlined),
                                    text: isPhone ? null : 'RULES',
                                  ),
                                  Tab(
                                    icon: const Icon(Icons.settings_outlined),
                                    text: isPhone ? null : l10n.settings.toUpperCase(),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    EngagementTimeline(
                                      customer: currentCustomer,
                                      engagements: engagements,
                                      provider: provider,
                                      onRespond: (engagement) => _showResponseDialog(context, provider, currentCustomer, engagement),
                                      onReviewDraft: (engagement) => _openAiSidebar('review', provider, currentCustomer, engagement: engagement),
                                    ),
                                    _buildProfileTab(context, provider, currentCustomer, engagements, l10n),
                                    _buildGuidelinesTab(context, provider, currentCustomer, l10n),
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
                  // Persistent Sidebar Placeholder (Desktop only)
                  if (!isPhone && isAnySidebarOpen)
                    SizedBox(width: sidebarWidth),
                ],
              ),
            ),
            
            // Scrim (Animated Overlay)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !isAnySidebarOpen,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isAiSidebarOpen = false;
                    _isAddScheduleSidebarOpen = false;
                  }),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isAnySidebarOpen ? 1.0 : 0.0,
                    child: Container(color: Colors.black26),
                  ),
                ),
              ),
            ),
            
            // Universal Sidebar (Animated Positioned)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: isAnySidebarOpen ? 0 : -sidebarWidth,
              top: 0,
              bottom: 0,
              width: sidebarWidth,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(-5, 0)),
                  ],
                ),
                child: _isAiSidebarOpen
                  ? _buildAiSidebarContent(context, provider, currentCustomer, l10n)
                  : _isAddScheduleSidebarOpen
                    ? _buildAddScheduleSidebar(context, provider, currentCustomer)
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSidebarContent(BuildContext context, AdvisorProvider provider, Customer customer, AppLocalizations l10n) {
    if (_aiSidebarMode == 'review') {
      return _buildDraftReviewSidebar(context, provider, customer);
    }

    final isProfile = _aiSidebarMode == 'profile';
    
    return SafeArea(
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
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _aiChatProvider == null || _isAiSidebarLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black12))
              : KeyValueChatView(provider: _aiChatProvider!),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _aiChatProvider == null || _aiChatProvider!.history.length < 2 || _isAiSidebarLoading ? null : () async {
                    setState(() => _isAiSidebarLoading = true);
                    final updated = isProfile
                      ? await provider.finalizeProfileRefinement(customer, _aiChatProvider!.history.map((m) => AiChatMessage(
                          text: m.text ?? "",
                          isUser: m.origin == MessageOrigin.user,
                        )).toList())
                      : await provider.finalizeGuidelinesRefinement(customer, _aiChatProvider!.history.map((m) => AiChatMessage(
                          text: m.text ?? "",
                          isUser: m.origin == MessageOrigin.user,
                        )).toList());
                    
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
    );
  }

  Widget _buildDraftReviewSidebar(BuildContext context, AdvisorProvider provider, Customer customer) {
    if (_activeReviewEngagement == null) return const SizedBox.shrink();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(_isRefiningDraft ? Icons.auto_awesome_outlined : Icons.edit_note_outlined, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _isRefiningDraft ? 'REFINE WITH AI' : 'REVIEW DRAFT',
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                  ),
                ),
                if (_isRefiningDraft)
                  IconButton(
                    onPressed: () => setState(() => _isRefiningDraft = false),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    tooltip: 'Back to Editor',
                  ),
                IconButton(
                  onPressed: () => setState(() => _isAiSidebarOpen = false),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isRefiningDraft
              ? (_aiChatProvider == null || _isAiSidebarLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.black12))
                  : KeyValueChatView(provider: _aiChatProvider!))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('MESSAGE DRAFT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                        TextButton.icon(
                          onPressed: provider.isGuestMode ? null : () => setState(() => _isRefiningDraft = true),
                          icon: const Icon(Icons.auto_awesome_outlined, size: 14),
                          label: const Text('REFINE WITH AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            foregroundColor: provider.isGuestMode ? Colors.grey : Colors.black,
                            backgroundColor: const Color(0xFFF9F9F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reviewDraftController,
                      maxLines: 7,
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
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
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('SEND'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                surfaceTintColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Delete Draft', style: TextStyle(fontWeight: FontWeight.w900)),
                                content: const Text('Are you sure you want to delete this message draft?'),
                                actions: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false), 
                                        child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          minimumSize: const Size(100, 44),
                                        ),
                                        child: const Text('DELETE'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await provider.deleteEngagement(customer, _activeReviewEngagement!);
                              if (mounted) {
                                setState(() => _isAiSidebarOpen = false);
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'DELETE DRAFT',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(44, 44),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _reviewDraftController.text));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                          },
                          icon: const Icon(Icons.copy_outlined, size: 20),
                          tooltip: 'COPY',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF9F9F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(44, 44),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Share.share(_reviewDraftController.text);
                          },
                          icon: const Icon(Icons.share_outlined, size: 20),
                          tooltip: 'SHARE',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF9F9F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(44, 44),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
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
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddScheduleSidebar(BuildContext context, AdvisorProvider provider, Customer customer) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const Icon(Icons.add_task_outlined, size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'ADD SCHEDULE',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isAddScheduleSidebarOpen = false),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RECURRENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Every ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _addScheduleCadenceController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _addSchedulePeriod,
                        underline: const SizedBox(),
                        items: ['days', 'weeks', 'months', 'years'].map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _addSchedulePeriod = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('START DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    height: 280,
                    child: CalendarDatePicker(
                      initialDate: _addScheduleStartDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      onDateChanged: (date) {
                        setState(() => _addScheduleStartDate = date);
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('END DATE (OPTIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    height: 280,
                    child: CalendarDatePicker(
                      initialDate: _addScheduleEndDate ?? _addScheduleStartDate.add(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      onDateChanged: (date) {
                        setState(() => _addScheduleEndDate = date);
                      },
                    ),
                  ),
                  if (_addScheduleEndDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton(
                        onPressed: () => setState(() => _addScheduleEndDate = null),
                        child: const Text('Clear end date', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _isAddScheduleLoading ? null : () async {
                setState(() => _isAddScheduleLoading = true);
                final schedule = EngagementSchedule(
                  scheduleId: const Uuid().v4(),
                  startDate: _addScheduleStartDate,
                  endDate: _addScheduleEndDate,
                  cadenceValue: int.tryParse(_addScheduleCadenceController.text) ?? 1,
                  cadencePeriod: _addSchedulePeriod,
                );
                
                final updatedSchedules = List<EngagementSchedule>.from(customer.schedules)..add(schedule);
                final updatedCustomer = customer.copyWith(schedules: updatedSchedules);
                final nextDate = updatedCustomer.calculateNextEngagementDate(DateTime.now());
                await provider.addCustomer(updatedCustomer.copyWith(nextEngagementDate: nextDate));
                
                if (mounted) {
                  setState(() {
                    _isAddScheduleLoading = false;
                    _isAddScheduleSidebarOpen = false;
                  });
                }
              },
              child: _isAddScheduleLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('ADD SCHEDULE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, AdvisorProvider provider, Customer customer, List<Engagement> engagements, AppLocalizations l10n) {
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
              initiallyExpanded: true,
              children: [
                _buildInfoRow(l10n.email.toUpperCase(), customer.email),
                _buildInfoRow('PHONE', customer.phoneNumber),
                _buildInfoRow('OCCUPATION', customer.occupation),
                _buildInfoRow('ADDRESS', customer.address),
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
                    tooltip: provider.isGuestMode ? 'AI Disabled in Demo' : 'Build Profile with AI',
                    onPressed: provider.isGuestMode ? null : () => _openAiSidebar('profile', provider, customer),
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
          _isEditingProfile
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
        ],
      ),
    );
  }

  Future<void> _saveProfile(AdvisorProvider provider) async {
    final currentCustomer = provider.customers.firstWhere(
      (c) => c.customerId == widget.customer.customerId,
      orElse: () => widget.customer,
    );
    final updatedCustomer = currentCustomer.copyWith(
      details: _profileController.text,
    );
    await provider.addCustomer(updatedCustomer);
    setState(() {
      _isEditingProfile = false;
    });
  }

  Widget _buildGuidelinesTab(BuildContext context, AdvisorProvider provider, Customer customer, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text('ENGAGEMENT SCHEDULES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
              trailing: TextButton.icon(
                onPressed: () => setState(() {
                  _isAddScheduleSidebarOpen = true;
                  _isAiSidebarOpen = false;
                  _addScheduleStartDate = DateTime.now();
                  _addScheduleEndDate = null;
                  _addScheduleCadenceController.text = '1';
                  _addSchedulePeriod = 'months';
                }),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
              ),
              children: [
                const SizedBox(height: 16),
                if (customer.schedules.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.black54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Using legacy schedule: Every ${customer.cadenceValue} ${customer.cadencePeriod}',
                            style: const TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...customer.schedules.map((schedule) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_repeat_outlined, size: 20, color: Colors.black87),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Every ${schedule.cadenceValue} ${schedule.cadencePeriod}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Starts: ${DateFormat('MMM d, y').format(schedule.startDate)}${schedule.endDate != null ? ' • Ends: ${DateFormat('MMM d, y').format(schedule.endDate!)}' : ''}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final updatedSchedules = List<EngagementSchedule>.from(customer.schedules)
                              ..removeWhere((s) => s.scheduleId == schedule.scheduleId);
                            final updatedCustomer = customer.copyWith(schedules: updatedSchedules);
                            // Recalculate next engagement date based on new schedules
                            final nextDate = updatedCustomer.calculateNextEngagementDate(DateTime.now());
                            await provider.addCustomer(updatedCustomer.copyWith(nextEngagementDate: nextDate));
                          },
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ENGAGEMENT RULES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    tooltip: provider.isGuestMode ? 'AI Disabled in Demo' : 'Refine Rules with AI',
                    onPressed: provider.isGuestMode ? null : () => _openAiSidebar('guidelines', provider, customer),
                  ),
                  IconButton(
                    icon: Icon(_isEditingRules ? Icons.check_circle_outline : Icons.edit_outlined, size: 18),
                    onPressed: () {
                      if (_isEditingRules) {
                        _saveRules(provider);
                      } else {
                        setState(() {
                          _isEditingRules = true;
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
          _isEditingRules
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
        ],
      ),
    );
  }

  Future<void> _saveRules(AdvisorProvider provider) async {
    final currentCustomer = provider.customers.firstWhere(
      (c) => c.customerId == widget.customer.customerId,
      orElse: () => widget.customer,
    );
    final updatedCustomer = currentCustomer.copyWith(
      guidelines: _guidelinesController.text,
    );
    await provider.addCustomer(updatedCustomer);
    setState(() {
      _isEditingRules = false;
    });
  }

  Widget _buildSettingsTab(BuildContext context, AdvisorProvider provider, Customer customer, AppLocalizations l10n) {
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

  void _showDeleteConfirmation(BuildContext context, AdvisorProvider provider, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Client?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, 
                  foregroundColor: Colors.white, 
                  elevation: 0,
                  minimumSize: const Size(100, 44),
                ),
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
        ],
      ),
    );
  }

  Widget _buildAiInsightsSection(BuildContext context, AdvisorProvider provider, Customer customer, Engagement engagement) {
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
                    side: const BorderSide(color: Color(0xFFEEEEEE)),
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
                const Text(
                  'PROPOSED PROFILE UPDATE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: MarkdownBody(
                    data: engagement.updatedDetailsDiff,
                    styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 13, height: 1.5)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => provider.approveResponse(customer, engagement),
                        child: const Text('APPROVE & UPDATE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => provider.dismissResponse(customer, engagement),
                      child: const Text('DISMISS'),
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

  void _showResponseDialog(BuildContext context, AdvisorProvider provider, Customer customer, Engagement engagement) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Client Response', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Paste client response here...',
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  await provider.receiveResponse(customer, engagement, controller.text);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
                child: const Text('PROCESS'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.black26),
          const SizedBox(width: 12),
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
}
