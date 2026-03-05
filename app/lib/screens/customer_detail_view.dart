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
  late TextEditingController _tagController;

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
    _tagController = TextEditingController();
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
    _tagController.dispose();
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
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: _buildHeader(context, currentCustomer, l10n, provider),
            ),
            
            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TabBar(
                isScrollable: true,
                dividerColor: Colors.transparent,
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
                    padding: const EdgeInsets.all(24),
                    children: [
                      if (currentCustomer.proposedDetails != null)
                        _buildProposedUpdateCard(
                          title: 'PROPOSED PROFILE UPDATE',
                          original: currentCustomer.details,
                          proposed: currentCustomer.proposedDetails!,
                          onApprove: () => provider.approveProposedDetails(currentCustomer),
                          onDismiss: () => provider.dismissProposedDetails(currentCustomer),
                        ),
                      _buildProfileSection(currentCustomer, provider, l10n),
                    ],
                  ),
                  
                  // Tab 3: Guidelines
                  ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      if (currentCustomer.proposedGuidelines != null)
                        _buildProposedUpdateCard(
                          title: 'PROPOSED GUIDELINES UPDATE',
                          original: currentCustomer.guidelines,
                          proposed: currentCustomer.proposedGuidelines!,
                          onApprove: () => provider.approveProposedGuidelines(currentCustomer),
                          onDismiss: () => provider.dismissProposedGuidelines(currentCustomer),
                        ),
                      _buildGuidelinesSection(currentCustomer, provider, l10n),
                      const SizedBox(height: 48),
                      _buildSchedulesSection(currentCustomer, provider),
                    ],
                  ),

                  // Tab 4: Client Info & Settings
                  ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildInfoSection(currentCustomer, provider, l10n),
                      const SizedBox(height: 48),
                      _buildDangerZone(currentCustomer, provider, l10n),
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
    required VoidCallback onApprove,
    required VoidCallback onDismiss,
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_outlined, size: 16),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 10)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI SUGGESTION:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(8)),
                  child: MarkdownBody(data: proposed),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('APPROVE & UPDATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                    OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(100, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                      child: const Text('DISMISS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
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
        title: const Text('Record Customer Response'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Enter what the customer said...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final response = controller.text.trim();
              if (response.isNotEmpty) {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(dialogContext);
                await provider.receiveResponse(customer, engagement, response);
              }
            },
            child: const Text('PROCESS WITH AI'),
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

  Widget _buildProfileSection(Customer customer, AdvisorProvider provider, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.profile.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
            IconButton(
              icon: Icon(_isEditingProfile ? Icons.check_circle_outline : Icons.edit_outlined, size: 16),
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
        const SizedBox(height: 8),
        if (_isEditingProfile)
          TextField(
            controller: _profileController,
            maxLines: null,
            style: const TextStyle(fontSize: 13, height: 1.6),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          )
        else
          MarkdownBody(data: customer.details),
      ],
    );
  }

  Widget _buildGuidelinesSection(Customer customer, AdvisorProvider provider, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('GUIDELINES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
            IconButton(
              icon: Icon(_isEditingRules ? Icons.check_circle_outline : Icons.edit_outlined, size: 16),
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
        const SizedBox(height: 8),
        if (_isEditingRules)
          TextField(
            controller: _guidelinesController,
            maxLines: null,
            style: const TextStyle(fontSize: 13, height: 1.6),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          )
        else
          MarkdownBody(data: customer.guidelines),
      ],
    );
  }

  Widget _buildInfoSection(Customer customer, AdvisorProvider provider, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PRIMARY CONTACT & INFO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
            IconButton(
              icon: Icon(_isEditingInfo ? Icons.check_circle_outline : Icons.edit_outlined, size: 16),
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
        _buildInfoField('FULL NAME', _nameController, _isEditingInfo),
        _buildInfoField('EMAIL ADDRESS', _emailController, _isEditingInfo),
        _buildInfoField('PHONE NUMBER', _phoneController, _isEditingInfo),
        _buildInfoField('OCCUPATION', _occupationController, _isEditingInfo),
        _buildInfoField('ADDRESS', _addressController, _isEditingInfo, maxLines: 2),
        
        const SizedBox(height: 32),
        const Text('TAGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...customer.tags.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onDeleted: () async {
                final updatedTags = List<String>.from(customer.tags)..remove(tag);
                await provider.addCustomer(customer.copyWith(tags: updatedTags));
              },
              backgroundColor: const Color(0xFFF9F9F9),
              side: const BorderSide(color: Color(0xFFEEEEEE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )),
            ActionChip(
              label: const Text('ADD TAG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => _showAddTagDialog(customer, provider),
              avatar: const Icon(Icons.add, size: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, bool isEditing, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          if (isEditing)
            TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
            )
          else
            Text(
              controller.text.isEmpty ? 'Not set' : controller.text,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.w600, 
                color: controller.text.isEmpty ? Colors.black26 : Colors.black
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(Customer customer, AdvisorProvider provider, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DANGER ZONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.red)),
          const SizedBox(height: 16),
          const Text('Deleting a client will permanently remove all their history, profile, and engagement schedules.', style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showDeleteCustomerDialog(customer, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              elevation: 0,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('DELETE CLIENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(Customer customer, AdvisorProvider provider) {
    _tagController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: _tagController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. High Priority'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final tag = _tagController.text.trim();
              if (tag.isNotEmpty) {
                final updatedTags = [...customer.tags, tag];
                await provider.addCustomer(customer.copyWith(tags: updatedTags));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCustomerDialog(Customer customer, AdvisorProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Client?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE PERMANENTLY'),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesSection(Customer customer, AdvisorProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ENGAGEMENT SCHEDULES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              onPressed: () => _showAddScheduleDialog(context, customer, provider),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (customer.schedules.isEmpty)
          const Text('No active schedules. Proactive discovery will use the default 30-day cadence.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))
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
                  title: Text('Every ${schedule.cadenceValue} ${schedule.cadencePeriod}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Starts: ${DateFormat('MMM d, y').format(schedule.startDate)}${schedule.endDate != null ? ' | Ends: ${DateFormat('MMM d, y').format(schedule.endDate!)}' : ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
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

  void _showAddScheduleDialog(BuildContext context, Customer customer, AdvisorProvider provider) {
    int cadenceValue = 1;
    String cadencePeriod = 'months';
    DateTime startDate = DateTime.now();
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Engagement Schedule', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Every'),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                      onChanged: (val) => cadenceValue = int.tryParse(val) ?? 1,
                      controller: TextEditingController(text: '1'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: cadencePeriod,
                    items: ['days', 'weeks', 'months', 'years'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setDialogState(() => cadencePeriod = val!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start Date', style: TextStyle(fontSize: 14)),
                subtitle: Text(DateFormat('MMM d, y').format(startDate)),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
                  if (picked != null) setDialogState(() => startDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final schedule = EngagementSchedule(
                  scheduleId: const Uuid().v4(),
                  startDate: startDate,
                  endDate: endDate,
                  cadenceValue: cadenceValue,
                  cadencePeriod: cadencePeriod,
                );
                final updatedSchedules = List<EngagementSchedule>.from(customer.schedules)..add(schedule);
                final updated = customer.copyWith(schedules: updatedSchedules);
                await provider.addCustomer(updated);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('ADD SCHEDULE'),
            ),
          ],
        ),
      ),
    );
  }
}
