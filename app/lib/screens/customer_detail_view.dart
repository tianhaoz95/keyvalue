import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/advisor_provider.dart';
import '../providers/ui_context_provider.dart';
import '../widgets/engagement_timeline.dart';
import '../widgets/loading_overlay.dart';
import '../theme.dart';
import 'add_schedule_screen.dart';

class CustomerDetailView extends StatefulWidget {
  final Customer customer;

  const CustomerDetailView({super.key, required this.customer});

  @override
  State<CustomerDetailView> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends State<CustomerDetailView> {
  bool _isEditingProfile = false;
  bool _isEditingRules = false;
  bool _isEditingInfo = false;

  late TextEditingController _profileController;
  late TextEditingController _guidelinesController;
  
  // Info Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _occupationController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _profileController = TextEditingController(text: widget.customer.details);
    _guidelinesController = TextEditingController(text: widget.customer.guidelines);
    
    _nameController = TextEditingController(text: widget.customer.name);
    _emailController = TextEditingController(text: widget.customer.email);
    _phoneController = TextEditingController(text: widget.customer.phoneNumber);
    _occupationController = TextEditingController(text: widget.customer.occupation);
    _addressController = TextEditingController(text: widget.customer.address);
  }

  @override
  void dispose() {
    _profileController.dispose();
    _guidelinesController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _addressController.dispose();
    super.dispose();
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
    final isCompact = screenWidth < 600;
    final horizontalPadding = isCompact ? 16.0 : 24.0;

    return LoadingOverlay(
      isLoading: provider.isProcessingResponse || provider.isGeneratingDraft,
      message: provider.isProcessingResponse ? 'AI Analyzing Response...' : 'AI Generating Draft...',
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            // Top Header Area
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 12),
              child: _buildHeader(context, currentCustomer, l10n, provider),
            ),
            
            // Tab Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8.0 : 12.0),
              child: TabBar(
                isScrollable: true,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontSize: isCompact ? 10 : 12, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                unselectedLabelStyle: TextStyle(fontSize: isCompact ? 10 : 12, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                tabs: const [
                  Tab(text: 'TIMELINE'),
                  Tab(text: 'PROFILE'),
                  Tab(text: 'GUIDELINES'),
                  Tab(text: 'CLIENT INFO'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Timeline
                  StreamBuilder<List<Engagement>>(
                    stream: provider.getCustomerEngagements(currentCustomer.customerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final engagements = snapshot.data ?? [];
                      return EngagementTimeline(
                        customer: currentCustomer,
                        engagements: engagements,
                        provider: provider,
                        onRespond: (engagement) => _showResponseDialog(context, currentCustomer, engagement, provider),
                      );
                    },
                  ),
                  
                  // Tab 2: Profile
                  ListView(
                    padding: EdgeInsets.all(horizontalPadding),
                    children: [
                      if (currentCustomer.proposedDetails != null)
                        _buildProposedUpdateCard(
                          title: 'PROPOSED PROFILE UPDATE',
                          original: currentCustomer.details,
                          proposed: currentCustomer.proposedDetails!,
                          summary: currentCustomer.proposedDetailsSummary,
                          onApprove: () => provider.approveProposedDetails(currentCustomer),
                          onDismiss: () => provider.dismissProposedDetails(currentCustomer),
                          isCompact: isCompact,
                        ),
                      _buildProfileSection(currentCustomer, provider, l10n, isCompact),
                    ],
                  ),
                  
                  // Tab 3: Guidelines
                  ListView(
                    padding: EdgeInsets.all(horizontalPadding),
                    children: [
                      if (currentCustomer.proposedGuidelines != null)
                        _buildProposedUpdateCard(
                          title: 'PROPOSED GUIDELINES UPDATE',
                          original: currentCustomer.guidelines,
                          proposed: currentCustomer.proposedGuidelines!,
                          summary: currentCustomer.proposedGuidelinesSummary,
                          onApprove: () => provider.approveProposedGuidelines(currentCustomer),
                          onDismiss: () => provider.dismissProposedGuidelines(currentCustomer),
                          isCompact: isCompact,
                        ),
                      _buildGuidelinesSection(currentCustomer, provider, l10n, isCompact),
                      const SizedBox(height: 32),
                      _buildChannelSection(currentCustomer, provider, isCompact),
                      const SizedBox(height: 48),
                      _buildSchedulesSection(currentCustomer, provider, isCompact),
                    ],
                  ),

                  // Tab 4: Client Info & Settings
                  ListView(
                    padding: EdgeInsets.all(horizontalPadding),
                    children: [
                      _buildInfoSection(currentCustomer, provider, l10n, isCompact),
                      const SizedBox(height: 48),
                      _buildDangerZone(currentCustomer, provider, l10n, isCompact),
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

  Widget _buildProposedUpdateCard({
    required String title,
    required String original,
    required String proposed,
    String? summary,
    required VoidCallback onApprove,
    required VoidCallback onDismiss,
    bool isCompact = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: isCompact ? 14 : 16),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: isCompact ? 9 : 10)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI SUGGESTION:', style: TextStyle(fontSize: isCompact ? 8 : 9, fontWeight: FontWeight.w900, color: Colors.grey)),
                if (summary != null && summary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('CHANGE SUMMARY', style: TextStyle(fontSize: isCompact ? 8 : 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(8)),
                  child: MarkdownBody(
                    data: proposed,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(fontSize: isCompact ? 12 : 13),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: Size(isCompact ? 100 : 120, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('APPROVE & UPDATE', style: TextStyle(fontSize: isCompact ? 9 : 10, fontWeight: FontWeight.w900)),
                    ),
                    OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(isCompact ? 80 : 100, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                      child: Text('DISMISS', style: TextStyle(fontSize: isCompact ? 9 : 10, fontWeight: FontWeight.w900)),
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

  void _showResponseDialog(BuildContext context, Customer customer, Engagement engagement, AdvisorProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('RECORD CUSTOMER RESPONSE'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Enter what the customer said...'),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext), 
                child: const Text('CANCEL', style: TextStyle(color: AppTheme.accentGrey, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final response = controller.text.trim();
                  if (response.isNotEmpty) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pop(dialogContext);
                    await provider.receiveResponse(customer, engagement, response);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 44),
                ),
                child: const Text('PROCESS WITH AI'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Customer customer, AppLocalizations l10n, AdvisorProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                onPressed: () => context.read<UiContextProvider>().setView(AppView.dashboard),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Hero(
                tag: 'avatar_${customer.customerId}',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black,
                  child: Text(customer.name[0], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
                    Text(customer.occupation, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactInfoRow(Icons.email_outlined, customer.email),
                    if (customer.phoneNumber.isNotEmpty)
                      _buildCompactInfoRow(Icons.phone_outlined, customer.phoneNumber),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  provider.generateManualDraft(customer);
                },
                icon: const Icon(Icons.auto_awesome_outlined, size: 12),
                label: const Text('GENERATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.read<UiContextProvider>().setView(AppView.dashboard),
          tooltip: 'Back to Dashboard',
        ),
        const SizedBox(width: 8),
        Hero(
          tag: 'avatar_${customer.customerId}',
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.black,
            child: Text(customer.name[0], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text(customer.occupation, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                provider.generateManualDraft(customer);
              },
              icon: const Icon(Icons.auto_awesome_outlined, size: 14),
              label: const Text('GENERATE OUTREACH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            _buildCompactInfoRow(Icons.email_outlined, customer.email),
            if (customer.phoneNumber.isNotEmpty)
              _buildCompactInfoRow(Icons.phone_outlined, customer.phoneNumber),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.black38),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(Customer customer, AdvisorProvider provider, AppLocalizations l10n, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.profile.toUpperCase(), style: TextStyle(fontSize: isCompact ? 9 : 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    final uiContext = context.read<UiContextProvider>();
                    uiContext.setAiEditMode(AiEditContext(
                      type: AiEditContextType.profile,
                      content: customer.details,
                    ));
                  },
                  icon: Icon(Icons.auto_awesome_outlined, size: isCompact ? 12 : 14, color: Colors.black),
                  label: Text(
                    'AI EDIT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: isCompact ? 9 : 10, 
                      color: Colors.black, 
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(_isEditingProfile ? Icons.check_circle_outline : Icons.edit_outlined, size: isCompact ? 18 : 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    if (_isEditingProfile) {
                      final updated = customer.copyWith(details: _profileController.text.trim());
                      await provider.addCustomer(updated);
                    }
                    setState(() => _isEditingProfile = !_isEditingProfile);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isEditingProfile)
          TextField(
            controller: _profileController,
            maxLines: null,
            style: TextStyle(fontSize: isCompact ? 12 : 13, height: 1.6),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          )
        else
          MarkdownBody(
            data: customer.details,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: isCompact ? 12 : 13, height: 1.6),
            ),
          ),
      ],
    );
  }

  Widget _buildGuidelinesSection(Customer customer, AdvisorProvider provider, AppLocalizations l10n, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GUIDELINES', style: TextStyle(fontSize: isCompact ? 9 : 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    final uiContext = context.read<UiContextProvider>();
                    uiContext.setAiEditMode(AiEditContext(
                      type: AiEditContextType.guidelines,
                      content: customer.guidelines,
                    ));
                  },
                  icon: Icon(Icons.auto_awesome_outlined, size: isCompact ? 12 : 14, color: Colors.black),
                  label: Text(
                    'AI EDIT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: isCompact ? 9 : 10, 
                      color: Colors.black, 
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(_isEditingRules ? Icons.check_circle_outline : Icons.edit_outlined, size: isCompact ? 18 : 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    if (_isEditingRules) {
                      final updated = customer.copyWith(guidelines: _guidelinesController.text.trim());
                      await provider.addCustomer(updated);
                    }
                    setState(() => _isEditingRules = !_isEditingRules);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isEditingRules)
          TextField(
            controller: _guidelinesController,
            maxLines: null,
            style: TextStyle(fontSize: isCompact ? 12 : 13, height: 1.6),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          )
        else
          MarkdownBody(
            data: customer.guidelines,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: isCompact ? 12 : 13, height: 1.6),
            ),
          ),
      ],
    );
  }

  Widget _buildChannelSection(Customer customer, AdvisorProvider provider, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COMMUNICATION CHANNEL', style: TextStyle(fontSize: isCompact ? 9 : 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildChannelOption(
              icon: Icons.email_outlined,
              label: 'EMAIL',
              isSelected: customer.preferredChannel == 'email',
              onTap: () => provider.addCustomer(customer.copyWith(preferredChannel: 'email')),
              isCompact: isCompact,
            ),
            const SizedBox(width: 12),
            _buildChannelOption(
              icon: Icons.sms_outlined,
              label: 'SMS MESSAGE',
              isSelected: customer.preferredChannel == 'sms',
              onTap: () => provider.addCustomer(customer.copyWith(preferredChannel: 'sms')),
              isCompact: isCompact,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isCompact ? 14 : 16, color: isSelected ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : Colors.black,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(Customer customer, AdvisorProvider provider, AppLocalizations l10n, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PRIMARY CONTACT & INFO', style: TextStyle(fontSize: isCompact ? 9 : 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
            IconButton(
              icon: Icon(_isEditingInfo ? Icons.check_circle_outline : Icons.edit_outlined, size: isCompact ? 16 : 18),
              onPressed: () async {
                if (_isEditingInfo) {
                  final updated = customer.copyWith(
                    name: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                    phoneNumber: _phoneController.text.trim(),
                    occupation: _occupationController.text.trim(),
                    address: _addressController.text.trim(),
                  );
                  await provider.addCustomer(updated);
                }
                setState(() => _isEditingInfo = !_isEditingInfo);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoField('FULL NAME', _nameController, _isEditingInfo, isCompact: isCompact),
        _buildInfoField('EMAIL ADDRESS', _emailController, _isEditingInfo, isCompact: isCompact),
        _buildInfoField('PHONE NUMBER', _phoneController, _isEditingInfo, isCompact: isCompact),
        _buildInfoField('OCCUPATION', _occupationController, _isEditingInfo, isCompact: isCompact),
        _buildInfoField('ADDRESS', _addressController, _isEditingInfo, isCompact: isCompact, maxLines: 2),
      ],
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, bool isEditing, {int maxLines = 1, bool isCompact = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: isCompact ? 8 : 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          if (isEditing)
            TextField(
              controller: controller,
              maxLines: maxLines,
              style: TextStyle(fontSize: isCompact ? 13 : 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
            )
          else
            Text(
              controller.text.isEmpty ? 'Not set' : controller.text,
              style: TextStyle(
                fontSize: isCompact ? 13 : 14, 
                fontWeight: FontWeight.w600, 
                color: controller.text.isEmpty ? Colors.black26 : Colors.black
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(Customer customer, AdvisorProvider provider, AppLocalizations l10n, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DANGER ZONE', style: TextStyle(fontSize: isCompact ? 9 : 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.red)),
          const SizedBox(height: 16),
          Text('Deleting a client will permanently remove all their history, profile, and engagement schedules.', style: TextStyle(fontSize: isCompact ? 11 : 12, color: Colors.black54)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showDeleteCustomerDialog(customer, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              elevation: 0,
              side: const BorderSide(color: Colors.red),
              minimumSize: Size(0, isCompact ? 36 : 40),
            ),
            child: Text('DELETE CLIENT', style: TextStyle(fontSize: isCompact ? 10 : 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCustomerDialog(Customer customer, AdvisorProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('DELETE CLIENT?'),
        content: Text('Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext), 
                child: const Text('CANCEL', style: TextStyle(color: AppTheme.accentGrey, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  await provider.deleteCustomer(customer.customerId);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    if (mounted) {
                      context.read<UiContextProvider>().setView(AppView.dashboard);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(100, 44),
                ),
                child: const Text('DELETE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesSection(Customer customer, AdvisorProvider provider, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ENGAGEMENT SCHEDULES', style: TextStyle(fontSize: isCompact ? 9 : 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
            IconButton(
              icon: Icon(Icons.add_circle_outline, size: isCompact ? 16 : 18),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddScheduleScreen(customer: widget.customer)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (customer.schedules.isEmpty)
          Text('No active schedules. Proactive discovery will use the default 30-day cadence.', style: TextStyle(fontSize: isCompact ? 11 : 12, color: Colors.grey, fontStyle: FontStyle.italic))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: customer.schedules.length,
            itemBuilder: (context, index) {
              final schedule = customer.schedules[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: const Color(0xFFF9F9F9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), 
                  side: const BorderSide(color: Color(0xFFEEEEEE))
                ),
                child: ListTile(
                  dense: true,
                  title: Text('Every ${schedule.cadenceValue} ${schedule.cadencePeriod}', style: TextStyle(fontSize: isCompact ? 13 : 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Starts: ${DateFormat('MMM d, y').format(schedule.startDate)}${schedule.endDate != null ? ' | Ends: ${DateFormat('MMM d, y').format(schedule.endDate!)}' : ''}',
                    style: TextStyle(fontSize: isCompact ? 11 : 12),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, size: isCompact ? 14 : 16, color: Colors.red),
                    onPressed: () async {
                      final updatedSchedules = List<EngagementSchedule>.from(customer.schedules)..removeAt(index);
                      final updated = customer.copyWith(schedules: updatedSchedules);
                      await provider.addCustomer(updated);
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
