import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/advisor_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/confirm_slider.dart';
import 'login_screen.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _nameController;
  late TextEditingController _firmController;
  bool _isEditingProfile = false;
  String _selectedPlan = 'Starter';
  String? _pendingPlan;

  @override
  void initState() {
    super.initState();
    final advisor = context.read<AdvisorProvider>().currentAdvisor;
    _nameController = TextEditingController(text: advisor?.name ?? '');
    _firmController = TextEditingController(text: advisor?.firmName ?? '');
    _selectedPlan = advisor?.subscriptionPlan ?? 'Starter';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdvisorProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final advisor = provider.currentAdvisor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final horizontalPadding = isCompact ? 16.0 : 24.0;

    if (advisor == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: EdgeInsets.all(horizontalPadding),
      children: [
        // Advisor Profile Section
        _buildSectionHeader(l10n.profile.toUpperCase(), isCompact),
        const SizedBox(height: 12),
        _buildProfileCard(provider, l10n, isCompact),

        const SizedBox(height: 32),

        // Subscription Section
        _buildSectionHeader('SUBSCRIPTION PLAN', isCompact),
        const SizedBox(height: 12),
        _buildPlanSelector(provider, isCompact),

        const SizedBox(height: 32),

        // Billing Section
        _buildSectionHeader('BILLING INFORMATION', isCompact),
        const SizedBox(height: 12),
        _buildBillingInfoCard(isCompact),

        const SizedBox(height: 32),

        // AI Settings Section
        _buildSectionHeader('AI CAPABILITIES', isCompact),
        const SizedBox(height: 12),
        _buildAiSettingsCard(provider, l10n, isCompact),

        const SizedBox(height: 32),

        // Preferences Section
        _buildSectionHeader('PREFERENCES', isCompact),
        const SizedBox(height: 12),
        _buildPreferencesCard(provider, l10n, isCompact),

        const SizedBox(height: 40),

        // Danger Zone
        _buildSectionHeader('ACCOUNT', isCompact),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            await provider.logout();
            if (mounted) {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.red,
            elevation: 0,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: isCompact ? 11 : 12)),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => _showDeleteAccountDialog(context, provider),
            child: Text('DELETE ACCOUNT', style: TextStyle(color: Colors.red, fontSize: isCompact ? 10 : 11, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isCompact) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isCompact ? 8 : 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildProfileCard(AdvisorProvider provider, AppLocalizations l10n, bool isCompact) {
    final advisor = provider.currentAdvisor!;
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: isCompact ? 18 : 20,
                backgroundColor: Colors.black,
                child: Icon(Icons.person, color: Colors.white, size: isCompact ? 18 : 20),
              ),
              IconButton(
                icon: Icon(_isEditingProfile ? Icons.check_circle_outline : Icons.edit_outlined, size: isCompact ? 16 : 18),
                onPressed: () async {
                  if (_isEditingProfile) {
                    final updated = advisor.copyWith(
                      name: _nameController.text.trim(),
                      firmName: _firmController.text.trim(),
                    );
                    await provider.updateProfile(updated);
                  }
                  setState(() => _isEditingProfile = !_isEditingProfile);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditingProfile) ...[
            TextField(
              controller: _nameController,
              style: TextStyle(fontSize: isCompact ? 12 : 13),
              decoration: const InputDecoration(labelText: 'NAME', isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firmController,
              style: TextStyle(fontSize: isCompact ? 12 : 13),
              decoration: const InputDecoration(labelText: 'FIRM NAME', isDense: true),
            ),
          ] else ...[
            Text(advisor.name, style: TextStyle(fontSize: isCompact ? 15 : 16, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(advisor.firmName, style: TextStyle(fontSize: isCompact ? 12 : 13, color: Colors.black54, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Text(advisor.email, style: TextStyle(fontSize: isCompact ? 11 : 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanSelector(AdvisorProvider provider, bool isCompact) {
    final plans = [
      {'name': 'Starter', 'price': '\$29/mo', 'features': 'Up to 10 clients'},
      {'name': 'Pro', 'price': '\$99/mo', 'features': 'Unlimited clients, AI features'},
      {'name': 'Enterprise', 'price': 'Custom', 'features': 'Dedicated support'},
    ];

    final showSlider = _pendingPlan != null && _pendingPlan != _selectedPlan;

    return Column(
      children: [
        ...plans.map((plan) {
          final isSelected = (_pendingPlan ?? _selectedPlan) == plan['name'];
          final isActualSelected = _selectedPlan == plan['name'];

          return GestureDetector(
            onTap: () {
              if (plan['name'] != _selectedPlan) {
                setState(() => _pendingPlan = plan['name']);
              } else {
                setState(() => _pendingPlan = null);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(isCompact ? 10 : 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withValues(alpha: 0.02) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.black : const Color(0xFFEEEEEE),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(plan['name']!.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: isCompact ? 10 : 11, letterSpacing: 1)),
                            if (isActualSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('CURRENT', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(plan['features']!, style: TextStyle(fontSize: isCompact ? 9 : 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(plan['price']!, style: TextStyle(fontWeight: FontWeight.w900, fontSize: isCompact ? 12 : 13)),
                ],
              ),
            ),
          );
        }),
        if (showSlider) ...[
          const SizedBox(height: 16),
          if (isCompact) ...[
            ConfirmSlider(
              text: 'Slide to confirm ${_pendingPlan}',
              isCompact: isCompact,
              onConfirm: () => _handlePlanChange(provider),
            ),
            const SizedBox(height: 12),
            _buildBillingNote(isCompact),
          ] else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handlePlanChange(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('CONFIRM PLAN CHANGE TO ${_pendingPlan?.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBillingNote(isCompact),
              ],
            ),
        ],
      ],
    );
  }

  Widget _buildBillingNote(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: isCompact ? 14 : 16, color: Colors.blue),
          SizedBox(width: isCompact ? 8 : 12),
          Expanded(
            child: Text(
              'Note: Plan changes take effect immediately. Pro-rated charges or credits will be applied to your next billing cycle on April 1, 2026.',
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlanChange(AdvisorProvider provider) async {
    if (_pendingPlan != null) {
      await provider.setSubscriptionPlan(_pendingPlan!);
      setState(() {
        _selectedPlan = _pendingPlan!;
        _pendingPlan = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan updated to $_selectedPlan'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildBillingInfoCard(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, size: isCompact ? 16 : 18, color: Colors.black54),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Visa ending in 4242',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 12 : 13),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text('EDIT', style: TextStyle(fontSize: isCompact ? 8 : 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          Divider(height: isCompact ? 12 : 16),
          Row(
            children: [
              Icon(Icons.history, size: isCompact ? 16 : 18, color: Colors.black54),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Next billing on April 1, 2026',
                  style: TextStyle(fontSize: isCompact ? 11 : 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiSettingsCard(AdvisorProvider provider, AppLocalizations l10n, bool isCompact) {
    String capabilityText;
    switch (provider.aiCapability) {
      case 'fast':
        capabilityText = 'Fast (Gemini Flash Lite)';
        break;
      case 'lite-preview':
        capabilityText = 'Lite Preview (Gemini 3.1 Flash Lite)';
        break;
      case 'preview':
        capabilityText = 'Preview (Gemini 3 Flash)';
        break;
      case 'pro':
      default:
        capabilityText = 'Pro (Gemini Flash)';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text('Model Capability', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 12 : 13)),
            subtitle: Text(capabilityText, style: TextStyle(fontSize: isCompact ? 10 : 11)),
            trailing: PopupMenuButton<String>(
              onSelected: provider.setAiCapability,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'fast', child: Text('Fast')),
                const PopupMenuItem(value: 'lite-preview', child: Text('Lite Preview')),
                const PopupMenuItem(value: 'pro', child: Text('Pro')),
                const PopupMenuItem(value: 'preview', child: Text('Preview')),
              ],
              child: Icon(Icons.tune, size: isCompact ? 16 : 18),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            dense: true,
            title: Text('Expressive AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 12 : 13)),
            subtitle: Text('Visual feedback', style: TextStyle(fontSize: isCompact ? 10 : 11)),
            value: provider.isExpressiveAiEnabled,
            activeColor: Colors.black,
            onChanged: provider.isGuestMode ? null : (val) => provider.setExpressiveAiEnabled(val),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            dense: true,
            title: Text('Multimodal AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 12 : 13)),
            subtitle: Text('Voice & images', style: TextStyle(fontSize: isCompact ? 10 : 11)),
            value: provider.isMultimodalAiEnabled,
            activeColor: Colors.black,
            onChanged: provider.isGuestMode ? null : (val) => provider.setMultimodalAiEnabled(val),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(AdvisorProvider provider, AppLocalizations l10n, bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text('Language', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 12 : 13)),
            subtitle: Text(provider.locale.languageCode == 'en' ? 'English' : 'Chinese', style: TextStyle(fontSize: isCompact ? 10 : 11)),
            trailing: PopupMenuButton<Locale>(
              onSelected: provider.setLocale,
              itemBuilder: (context) => [
                const PopupMenuItem(value: Locale('en'), child: Text('English')),
                const PopupMenuItem(value: Locale('zh'), child: Text('中文 (Chinese)')),
              ],
              child: Icon(Icons.language, size: isCompact ? 16 : 18),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AdvisorProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('This action is permanent and will delete all your client data. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteAccount();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE PERMANENTLY'),
          ),
        ],
      ),
    );
  }
}
