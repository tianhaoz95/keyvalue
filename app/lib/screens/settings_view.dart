import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/advisor_provider.dart';
import '../providers/ui_context_provider.dart';
import '../l10n/app_localizations.dart';
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
  String _selectedPlan = 'Pro';

  @override
  void initState() {
    super.initState();
    final advisor = context.read<AdvisorProvider>().currentAdvisor;
    _nameController = TextEditingController(text: advisor?.name ?? '');
    _firmController = TextEditingController(text: advisor?.firmName ?? '');
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

    if (advisor == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Advisor Profile Section
        _buildSectionHeader(l10n.profile.toUpperCase()),
        const SizedBox(height: 12),
        _buildProfileCard(provider, l10n),

        const SizedBox(height: 32),

        // Subscription Section
        _buildSectionHeader('SUBSCRIPTION PLAN'),
        const SizedBox(height: 12),
        _buildPlanSelector(),

        const SizedBox(height: 32),

        // Billing Section
        _buildSectionHeader('BILLING INFORMATION'),
        const SizedBox(height: 12),
        _buildBillingInfoCard(),

        const SizedBox(height: 32),

        // AI Settings Section
        _buildSectionHeader('AI CAPABILITIES'),
        const SizedBox(height: 12),
        _buildAiSettingsCard(provider, l10n),

        const SizedBox(height: 32),

        // Preferences Section
        _buildSectionHeader('PREFERENCES'),
        const SizedBox(height: 12),
        _buildPreferencesCard(provider, l10n),

        const SizedBox(height: 40),

        // Danger Zone
        _buildSectionHeader('ACCOUNT'),
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
          child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => _showDeleteAccountDialog(context, provider),
            child: const Text('DELETE ACCOUNT', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildProfileCard(AdvisorProvider provider, AppLocalizations l10n) {
    final advisor = provider.currentAdvisor!;
    return Container(
      padding: const EdgeInsets.all(16),
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
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.black,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              IconButton(
                icon: Icon(_isEditingProfile ? Icons.check_circle_outline : Icons.edit_outlined, size: 18),
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
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(labelText: 'NAME', isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firmController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(labelText: 'FIRM NAME', isDense: true),
            ),
          ] else ...[
            Text(advisor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(advisor.firmName, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(advisor.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanSelector() {
    final plans = [
      {'name': 'Starter', 'price': '\$29/mo', 'features': 'Up to 10 clients'},
      {'name': 'Pro', 'price': '\$99/mo', 'features': 'Unlimited clients, AI features'},
      {'name': 'Enterprise', 'price': 'Custom', 'features': 'Dedicated support'},
    ];

    return Column(
      children: plans.map((plan) {
        final isSelected = _selectedPlan == plan['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedPlan = plan['name']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
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
                      Text(plan['name']!.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(plan['features']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                Text(plan['price']!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBillingInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, size: 18, color: Colors.black54),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Visa ending in 4242',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('EDIT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.history, size: 18, color: Colors.black54),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Next billing on April 1, 2026',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiSettingsCard(AdvisorProvider provider, AppLocalizations l10n) {
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
            title: const Text('Model Capability', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text(provider.aiCapability == 'fast' ? 'Fast (Gemini Flash Lite)' : 'Pro (Gemini Flash)', style: const TextStyle(fontSize: 11)),
            trailing: PopupMenuButton<String>(
              onSelected: provider.setAiCapability,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'fast', child: Text('Fast')),
                const PopupMenuItem(value: 'pro', child: Text('Pro')),
              ],
              child: const Icon(Icons.tune, size: 18),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            dense: true,
            title: const Text('Expressive AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: const Text('Visual feedback', style: TextStyle(fontSize: 11)),
            value: provider.isExpressiveAiEnabled,
            activeColor: Colors.black,
            onChanged: provider.isGuestMode ? null : (val) => provider.setExpressiveAiEnabled(val),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            dense: true,
            title: const Text('Multimodal AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: const Text('Voice & images', style: TextStyle(fontSize: 11)),
            value: provider.isMultimodalAiEnabled,
            activeColor: Colors.black,
            onChanged: provider.isGuestMode ? null : (val) => provider.setMultimodalAiEnabled(val),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(AdvisorProvider provider, AppLocalizations l10n) {
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
            title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text(provider.locale.languageCode == 'en' ? 'English' : 'Chinese', style: const TextStyle(fontSize: 11)),
            trailing: PopupMenuButton<Locale>(
              onSelected: provider.setLocale,
              itemBuilder: (context) => [
                const PopupMenuItem(value: Locale('en'), child: Text('English')),
                const PopupMenuItem(value: Locale('zh'), child: Text('中文 (Chinese)')),
              ],
              child: const Icon(Icons.language, size: 18),
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
