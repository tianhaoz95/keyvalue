import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feedback/feedback.dart';
import 'package:intl/intl.dart';
import '../providers/cpa_provider.dart';
import '../models/customer.dart';
import '../services/ai_service.dart';
import '../widgets/pending_review_list.dart';
import '../widgets/loading_overlay.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import '../services/chat_provider.dart';
import '../widgets/chat_view.dart';
import 'customer_detail_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CustomerSortOption _sortOption = CustomerSortOption.nextContact;
  bool _isSearching = false;

  // Sidebar States
  bool _isAiOnboardingOpen = false;
  bool _isManualAddOpen = false;
  bool _isSettingsOpen = false;
  String? _editingField;
  final _editingController = TextEditingController();
  KeyValueChatProvider? _onboardingChatProvider;
  bool _isAiOnboardingLoading = false;

  // Manual Add Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailsController = TextEditingController();
  final _guidelinesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _loadSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final sortIndex = prefs.getInt('customerSortOption') ?? CustomerSortOption.nextContact.index;
    setState(() {
      _sortOption = CustomerSortOption.values[sortIndex];
    });
  }

  Future<void> _updateSortPreference(CustomerSortOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('customerSortOption', option.index);
    setState(() {
      _sortOption = option;
    });
  }

  void _startAiOnboarding(CpaProvider provider) async {
    setState(() {
      _isAiOnboardingOpen = true;
      _isManualAddOpen = false;
      _isSettingsOpen = false;
      _onboardingChatProvider = KeyValueChatProvider(
        aiService: provider.aiService,
        context: ChatContext.onboarding,
        cpaProvider: provider,
        isExpressiveAiEnabled: provider.isExpressiveAiEnabled,
        onConferenceReady: (_) async {
          if (_onboardingChatProvider == null) return;
          setState(() => _isAiOnboardingLoading = true);
          final customer = await provider.extractCustomerFromOnboarding(
            _onboardingChatProvider!.history.map((m) => AiChatMessage(
              text: m.text ?? "",
              isUser: m.origin == MessageOrigin.user,
            )).toList()
          );
          if (mounted) {
            setState(() => _isAiOnboardingLoading = false);
            if (customer != null) {
              _showOnboardingReviewDialog(customer, provider);
            }
          }
        },
      );
      _isAiOnboardingLoading = true;
    });

    final response = await provider.getOnboardingResponse([]);
    if (mounted && _onboardingChatProvider != null) {
      setState(() {
        _onboardingChatProvider!.history = [
          ChatMessage(
            text: response,
            origin: MessageOrigin.llm,
            attachments: const [],
          )
        ];
        _isAiOnboardingLoading = false;
      });
    }
  }

  void _startManualAdd() async {
    // Immediately open sidebar
    setState(() {
      _isManualAddOpen = true;
      _isAiOnboardingOpen = false;
      _isSettingsOpen = false;
      _nameController.clear();
      _emailController.clear();
      _occupationController.clear();
      _phoneController.clear();
      _addressController.clear();
      _detailsController.clear();
      _guidelinesController.clear();
    });
  }

  void _toggleSettings() {
    setState(() {
      _isSettingsOpen = !_isSettingsOpen;
      if (_isSettingsOpen) {
        _isAiOnboardingOpen = false;
        _isManualAddOpen = false;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _editingController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _detailsController.dispose();
    _guidelinesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CpaProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final allCustomers = provider.customers;
    final cpa = provider.currentCpa;
    final isDiscovering = provider.isDiscovering;

    if (cpa == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Filter customers with drafts for Urgent Actions
    final pendingReviews = allCustomers.where((c) => c.hasActiveDraft).toList();

    // Filter and sort customers for the main list based on search and sort option
    final filteredCustomers = allCustomers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             c.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    filteredCustomers.sort((a, b) {
      if (_sortOption == CustomerSortOption.name) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else {
        return a.nextEngagementDate.compareTo(b.nextEngagementDate);
      }
    });

    final isAnySidebarOpen = _isAiOnboardingOpen || _isManualAddOpen || _isSettingsOpen;
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;
    final sidebarWidth = isPhone ? screenWidth : screenWidth * 0.35;

    return LoadingOverlay(
      isLoading: isDiscovering,
      message: 'AI Thinking...',
      child: Scaffold(
        appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo_120.png', 
                  height: 28,
                  color: Colors.black,
                ),
                const SizedBox(width: 12),
                Text(cpa.firmName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_outlined),
            tooltip: 'AI Scan for Actions',
            onPressed: isDiscovering ? null : () => provider.discoverProactiveTasks(),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'AI Onboarding',
            onPressed: () => _startAiOnboarding(provider),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Client',
            onPressed: _startManualAdd,
          ),
          IconButton(
            icon: const Icon(Icons.feedback_outlined),
            tooltip: 'Send Feedback',
            onPressed: () {
              BetterFeedback.of(context).show((feedback) {
                // Here you would send the feedback to your backend or a service
                debugPrint('Feedback text: ${feedback.text}');
                debugPrint('Feedback screenshot: ${feedback.screenshot.length} bytes');
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _toggleSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Dashboard Content
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Welcome Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 12.0),
                        color: Colors.white,
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${l10n.welcomeBack}, ${cpa.name.split(' ')[0]}',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                                ),
                                if (isDiscovering)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                               l10n.portfolioStats(allCustomers.length),
                               style: const TextStyle(color: Colors.grey, fontSize: 14),
                             ),
                            ],
                            ),
                            ),

                            // Urgent Actions Section
                            if (pendingReviews.isNotEmpty) ...[
                            PendingReviewList(customers: pendingReviews),
                            ],

                            const SizedBox(height: 32),
                            SizedBox(
                              height: 48,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 12, 0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.clients,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.black54),
                                    ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        width: _isSearching ? 200 : 0,
                                        height: 36,
                                        margin: EdgeInsets.symmetric(horizontal: _isSearching ? 12.0 : 0),
                                        child: ClipRect(
                                          child: SizedBox(
                                            width: 200,
                                            child: TextField(
                                              controller: _searchController,
                                              autofocus: true,
                                              textAlign: TextAlign.left,
                                              textAlignVertical: TextAlignVertical.center,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                              decoration: InputDecoration(
                                                hintText: 'Search...',
                                                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal),
                                                filled: true,
                                                fillColor: Colors.black.withValues(alpha: 0.04),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(18),
                                                  borderSide: BorderSide.none,
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(18),
                                                  borderSide: BorderSide.none,
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(18),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(_isSearching ? Icons.close : Icons.search_outlined, size: 20, color: Colors.black54),
                                    onPressed: () {
                                      setState(() {
                                        if (_isSearching) {
                                          _isSearching = false;
                                          _searchController.clear();
                                          _searchQuery = '';
                                        } else {
                                          _isSearching = true;
                                        }
                                      });
                                    },
                                  ),
                                  PopupMenuButton<CustomerSortOption>(
                                    icon: const Icon(Icons.sort_outlined, size: 20, color: Colors.black54),
                                    tooltip: 'Sort Clients',
                                    onSelected: _updateSortPreference,
                                    itemBuilder: (context) => [
                                      CheckedPopupMenuItem(
                                        value: CustomerSortOption.name,
                                        checked: _sortOption == CustomerSortOption.name,
                                        child: const Text('Sort by Name'),
                                      ),
                                      CheckedPopupMenuItem(
                                        value: CustomerSortOption.nextContact,
                                        checked: _sortOption == CustomerSortOption.nextContact,
                                        child: const Text('Sort by Next Contact'),
                                      ),
                                    ],
                                  ),
                                  ],
                                ),
                              ),
                            ),
                      
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCustomers.length,
                        padding: const EdgeInsets.only(bottom: 100),
                        separatorBuilder: (_, index) => const Divider(height: 1, indent: 24, endIndent: 24),
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          return _buildCustomerTile(context, customer);
                        },
                      ),
                    ],
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
                onTap: () {
                  setState(() {
                    _isAiOnboardingOpen = false;
                    _isManualAddOpen = false;
                    _isSettingsOpen = false;
                  });
                },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isAnySidebarOpen ? 1.0 : 0.0,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          
          // Sidebar Container (Animated Positioned)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: isAnySidebarOpen ? 0 : -sidebarWidth,
            top: 0,
            bottom: 0,
            width: sidebarWidth,
            child: Row(
              children: [
                Expanded(
                  child: _isAiOnboardingOpen
                    ? _buildAiOnboardingSidebar(context, provider, l10n)
                    : _isManualAddOpen
                      ? _buildManualAddSidebar(context, provider, l10n)
                      : _isSettingsOpen
                        ? _buildSettingsSidebar(context, provider, l10n)
                        : const SizedBox.shrink(),
                ),
              ],
            ),          ),
        ],
      ),
    ));
  }

  Widget _buildAiOnboardingSidebar(BuildContext context, CpaProvider provider, AppLocalizations l10n) {
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
                      l10n.aiOnboarding.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isAiOnboardingOpen = false),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _onboardingChatProvider == null || _isAiOnboardingLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black12))
                : KeyValueChatView(provider: _onboardingChatProvider!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualAddSidebar(BuildContext context, CpaProvider provider, AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Icon(Icons.person_add_outlined, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.addClient.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isManualAddOpen = false),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'NAME')),
                  const SizedBox(height: 16),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'EMAIL')),
                  const SizedBox(height: 16),
                  TextField(controller: _occupationController, decoration: const InputDecoration(labelText: 'OCCUPATION')),
                  const SizedBox(height: 16),
                  TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'PHONE')),
                  const SizedBox(height: 16),
                  TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'ADDRESS')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _detailsController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'CLIENT DETAILS (MARKDOWN)'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _guidelinesController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'ENGAGEMENT RULES (MARKDOWN)'),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name and Email are required')),
                        );
                        return;
                      }
                      
                      final customer = Customer(
                        customerId: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        occupation: _occupationController.text.trim(),
                        phoneNumber: _phoneController.text.trim(),
                        address: _addressController.text.trim(),
                        details: _detailsController.text.trim(),
                        guidelines: _guidelinesController.text.trim(),
                        engagementFrequencyDays: 30,
                        nextEngagementDate: DateTime.now(),
                        lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
                        hasActiveDraft: false,
                      );
                      
                      await provider.addCustomer(customer);
                      if (mounted) {
                        setState(() => _isManualAddOpen = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${customer.name} added')),
                          );
                        }
                      }
                    },
                    child: Text(l10n.addClient.toUpperCase()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSidebar(BuildContext context, CpaProvider provider, AppLocalizations l10n) {
    final cpa = provider.currentCpa!;
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.settings.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isSettingsOpen = false),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(l10n.profile.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                  const SizedBox(height: 24),
                  _buildSidebarProfileCard(context, provider, cpa, l10n),
                  const SizedBox(height: 56),
                  Text('AI CAPABILITY', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                  const SizedBox(height: 24),
                  _buildSidebarAiCapabilitySelector(context, provider),
                  const SizedBox(height: 32),
                  const Text(
                    'EXPERIMENTAL FEATURES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Expressive AI UI',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                    subtitle: const Text(
                      'Enable real-time client preview cards during onboarding conversations.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    value: provider.isExpressiveAiEnabled,
                    onChanged: (value) {
                      provider.setExpressiveAiEnabled(value);
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(l10n.account.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),                  const SizedBox(height: 24),
                  _buildSidebarLanguageSelector(context, provider),
                  const SizedBox(height: 16),
                  _buildSidebarActionItem(
                    context,
                    icon: Icons.logout_outlined,
                    title: l10n.logout,
                    onTap: () async {
                      await provider.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSidebarActionItem(
                    context,
                    icon: Icons.delete_outline,
                    title: l10n.deleteAccount,
                    isDestructive: true,
                    onTap: () => _showSidebarDeleteAccountDialog(context, provider, l10n),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarLanguageSelector(BuildContext context, CpaProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.locale.languageCode,
          isExpanded: true,
          icon: const Icon(Icons.language_outlined, size: 20),
          onChanged: (String? code) {
            if (code != null) {
              provider.setLocale(Locale(code));
            }
          },
          items: const [
            DropdownMenuItem(value: 'en', child: Text('ENGLISH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1))),
            DropdownMenuItem(value: 'zh', child: Text('中文 (CHINESE)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1))),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarAiCapabilitySelector(BuildContext context, CpaProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.aiCapability,
          isExpanded: true,
          icon: const Icon(Icons.bolt_outlined, size: 20),
          onChanged: (String? value) {
            if (value != null) {
              provider.setAiCapability(value);
            }
          },
          items: const [
            DropdownMenuItem(value: 'fast', child: Text('FAST (FLASH LITE)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1))),
            DropdownMenuItem(value: 'pro', child: Text('PRO (FLASH)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1))),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarProfileCard(BuildContext context, CpaProvider provider, dynamic cpa, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          _buildSidebarInfoRow(
            context,
            provider,
            'NAME',
            'NAME', 
            cpa.name, 
            (val) => cpa.copyWith(name: val),
          ),
          const Divider(height: 32),
          _buildSidebarInfoRow(
            context,
            provider,
            'FIRM',
            'FIRM', 
            cpa.firmName, 
            (val) => cpa.copyWith(firmName: val),
          ),
          const Divider(height: 32),
          _buildSidebarInfoRow(
            context,
            provider,
            'EMAIL',
            'EMAIL', 
            cpa.email, 
            (val) => cpa.copyWith(email: val),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarInfoRow(
    BuildContext context,
    CpaProvider provider,
    String fieldKey,
    String label, 
    String value, 
    dynamic Function(String) copyWith,
  ) {
    final isEditing = _editingField == fieldKey;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              if (isEditing)
                TextField(
                  controller: _editingController,
                  autofocus: true,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.5)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.0)),
                    filled: false,
                  ),
                  onSubmitted: (val) async {
                    final updatedCpa = copyWith(val.trim());
                    await provider.updateProfile(updatedCpa);
                    setState(() => _editingField = null);
                  },
                )
              else
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
        IconButton(
          icon: Icon(isEditing ? Icons.check_circle_outline : Icons.edit_outlined, 
                     size: 16, 
                     color: isEditing ? Colors.black : Colors.black54),
          onPressed: () async {
            if (isEditing) {
              final updatedCpa = copyWith(_editingController.text.trim());
              await provider.updateProfile(updatedCpa);
              setState(() => _editingField = null);
            } else {
              setState(() {
                _editingField = fieldKey;
                _editingController.text = value;
              });
            }
          },
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildSidebarActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.black;
    return Container(
      decoration: BoxDecoration(
        color: isDestructive ? Colors.redAccent.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDestructive ? Colors.redAccent.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          title.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
        ),
        trailing: const Icon(Icons.chevron_right_outlined, color: Colors.black12, size: 18),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSidebarDeleteAccountDialog(BuildContext context, CpaProvider provider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('This will permanently delete all your data and access. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await provider.deleteAccount();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(l10n.deleteAccount.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _showOnboardingReviewDialog(Customer customer, CpaProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review New Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReviewField('NAME', customer.name),
              _buildReviewField('EMAIL', customer.email),
              _buildReviewField('OCCUPATION', customer.occupation),
              _buildReviewField('RULES', customer.guidelines),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await provider.addCustomer(customer);
              if (mounted) {
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  setState(() => _isAiOnboardingOpen = false); // Close sidebar
                }
              }
            },
            child: const Text('CREATE CLIENT'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? 'Not found' : value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCustomerTile(BuildContext context, Customer customer) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(customer: customer),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${customer.customerId}',
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.black12,
                child: Text(
                  customer.name[0],
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)
                  ),
                  Text(
                    customer.email,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('MMM d, y').format(customer.nextEngagementDate),
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const Icon(Icons.chevron_right, color: Colors.black12, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }}
