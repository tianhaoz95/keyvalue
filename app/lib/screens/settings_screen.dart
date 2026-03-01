import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/cpa_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CpaProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final cpa = provider.currentCpa;

    if (cpa == null) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Text(l10n.profile.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildModernProfileCard(context, provider, cpa, l10n),
          const SizedBox(height: 56),
          Text(l10n.account.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildModernLanguageSelector(context, provider),
          const SizedBox(height: 16),
          _buildModernActionItem(
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
          _buildModernActionItem(
            context,
            icon: Icons.delete_outline,
            title: l10n.deleteAccount,
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(context, provider, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLanguageSelector(BuildContext context, CpaProvider provider) {
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

  Widget _buildModernProfileCard(BuildContext context, CpaProvider provider, dynamic cpa, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          _buildModernInfoRow('NAME', cpa.name),
          const Divider(height: 32),
          _buildModernInfoRow('FIRM', cpa.firmName),
          const Divider(height: 32),
          _buildModernInfoRow('EMAIL', cpa.email),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _showEditProfileDialog(context, provider, l10n),
            child: Text(l10n.saveChanges.toUpperCase()),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }

  Widget _buildModernActionItem(
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
        trailing: Icon(Icons.chevron_right, color: color, size: 18),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, CpaProvider provider, AppLocalizations l10n) {
    final cpa = provider.currentCpa!;
    final nameController = TextEditingController(text: cpa.name);
    final firmController = TextEditingController(text: cpa.firmName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profile, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 16),
            TextField(controller: firmController, decoration: const InputDecoration(labelText: 'Firm Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final updatedCpa = cpa.copyWith(
                name: nameController.text.trim(),
                firmName: firmController.text.trim(),
              );
              await provider.updateProfile(updatedCpa);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.saveChanges.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, CpaProvider provider, AppLocalizations l10n) {
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
}
