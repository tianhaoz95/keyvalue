import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../providers/advisor_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/confirm_slider.dart';
import '../theme.dart';
import 'login_screen.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _nameController;
  late TextEditingController _firmController;
  late TextEditingController _cardHolderController;
  late TextEditingController _cardNumberController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;
  late TextEditingController _zipController;
  late TextEditingController _twilioSidController;
  late TextEditingController _twilioTokenController;
  late TextEditingController _sendgridApiKeyController;
  late TextEditingController _sendgridSenderController;
  late TextEditingController _firmEmailController;

  bool _isEditingProfile = false;
  bool _isEditingBilling = false;
  bool _isSavingBilling = false;
  bool _isEditingTwilio = false;
  bool _isEditingSendGrid = false;
  bool _isSearchingNumbers = false;
  List<String> _availableNumbers = [];

  String _selectedPlan = 'Starter';
  String? _pendingPlan;

  @override
  void initState() {
    super.initState();
    final advisor = context.read<AdvisorProvider>().currentAdvisor;
    _nameController = TextEditingController(text: advisor?.name ?? '');
    _firmController = TextEditingController(text: advisor?.firmName ?? '');
    _cardHolderController = TextEditingController(text: advisor?.cardHolderName ?? '');
    _cardNumberController = TextEditingController(text: advisor?.cardNumber ?? '');
    _expiryController = TextEditingController(text: advisor?.expiryDate ?? '');
    _cvvController = TextEditingController(text: advisor?.cvv ?? '');
    _zipController = TextEditingController(text: advisor?.zipCode ?? '');
    _twilioSidController = TextEditingController(text: advisor?.twilioAccountSid ?? '');
    _twilioTokenController = TextEditingController(text: advisor?.twilioAuthToken ?? '');
    _sendgridApiKeyController = TextEditingController(text: advisor?.sendgridApiKey ?? '');
    _sendgridSenderController = TextEditingController(text: advisor?.sendgridVerifiedSender ?? '');
    _firmEmailController = TextEditingController(text: advisor?.firmEmailAddress ?? '');
    _selectedPlan = advisor?.subscriptionPlan ?? 'Starter';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firmController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _zipController.dispose();
    _twilioSidController.dispose();
    _twilioTokenController.dispose();
    _sendgridApiKeyController.dispose();
    _sendgridSenderController.dispose();
    _firmEmailController.dispose();
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

        // Twilio Section
        _buildSectionHeader('TWILIO SMS INTEGRATION', isCompact),
        const SizedBox(height: 12),
        _buildTwilioCard(provider, isCompact),

        const SizedBox(height: 32),

        // SendGrid Section
        _buildSectionHeader('SENDGRID EMAIL INTEGRATION', isCompact),
        const SizedBox(height: 12),
        _buildSendGridCard(provider, isCompact),

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
        if (!provider.isDemoMode) ...[
          ElevatedButton(
            onPressed: () => _showChangePasswordDialog(context, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBlack,
              elevation: 0,
              side: const BorderSide(color: Color(0xFFEEEEEE)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('CHANGE PASSWORD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: isCompact ? 11 : 12)),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton(
          onPressed: () async {
            final navigator = Navigator.of(context, rootNavigator: true);
            await provider.logout();
            if (mounted) {
              navigator.pushAndRemoveUntil(
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

  void _showChangePasswordDialog(BuildContext context, AdvisorProvider provider) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CHANGE PASSWORD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
                validator: (val) => val == null || val.isEmpty ? 'Current password is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'New password is required';
                  if (val.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Confirm your new password';
                  if (val != newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await provider.changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
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
    final isPro = advisor.subscriptionPlan == 'Pro' || advisor.subscriptionPlan == 'Enterprise';

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: isCompact ? 22 : 24,
                backgroundColor: Colors.black,
                child: Icon(Icons.person, color: Colors.white, size: isCompact ? 22 : 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isEditingProfile 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          style: TextStyle(fontSize: isCompact ? 12 : 13),
                          decoration: const InputDecoration(labelText: 'NAME', isDense: true),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _firmController,
                          style: TextStyle(fontSize: isCompact ? 12 : 13),
                          decoration: const InputDecoration(labelText: 'FIRM NAME', isDense: true),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                advisor.name, 
                                style: TextStyle(fontSize: isCompact ? 14 : 15, fontWeight: FontWeight.w900), 
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                advisor.firmName, 
                                style: TextStyle(fontSize: isCompact ? 11 : 12, color: Colors.black54, fontWeight: FontWeight.w600), 
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          advisor.email, 
                          style: TextStyle(fontSize: isCompact ? 10 : 11, color: Colors.grey), 
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
              ),
              const SizedBox(width: 8),
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
          const Divider(height: 32),
          Text(
            'VIRTUAL PHONE NUMBER',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: isCompact ? 8 : 9, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          if (isPro) ...[
            Row(
              children: [
                Icon(Icons.phone_android, size: isCompact ? 16 : 18, color: Colors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    advisor.firmPhoneNumber.isEmpty ? 'Generating...' : advisor.firmPhoneNumber,
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 14, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'VIRTUAL EMAIL ADDRESS',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: isCompact ? 8 : 9, color: Colors.grey, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email_outlined, size: isCompact ? 16 : 18, color: Colors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    advisor.firmEmailAddress.isEmpty ? 'Not set' : advisor.firmEmailAddress,
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 14, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 14, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text('PRO FEATURE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.amber.shade900)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upgrade to PRO for a virtual phone number. STARTER plan requires manual message send and receive.',
                    style: TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
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
              text: 'Slide to confirm $_pendingPlan',
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
    final provider = context.watch<AdvisorProvider>();
    final advisor = provider.currentAdvisor!;
    final last4 = advisor.cardNumber.length >= 4 
        ? advisor.cardNumber.substring(advisor.cardNumber.length - 4) 
        : '****';
    
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
              Row(
                children: [
                  Icon(Icons.credit_card, size: isCompact ? 16 : 18, color: Colors.black54),
                  const SizedBox(width: 12),
                  Text(
                    _isEditingBilling ? 'SECURE STRIPE BILLING' : 'PAYMENT METHOD',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: isCompact ? 9 : 10, letterSpacing: 0.5),
                  ),
                ],
              ),
              _isSavingBilling 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : TextButton(
                    onPressed: () async {
                      if (_isEditingBilling) {
                        setState(() => _isSavingBilling = true);
                        try {
                          await provider.updateBillingInfo(
                            cardHolderName: _cardHolderController.text.trim(),
                            zipCode: _zipController.text.trim(),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Billing information updated securely.')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                          // Return early so we don't exit editing mode on error
                          setState(() => _isSavingBilling = false);
                          return;
                        } finally {
                          if (mounted) {
                            setState(() => _isSavingBilling = false);
                          }
                        }
                      }
                      setState(() => _isEditingBilling = !_isEditingBilling);
                    },
                    child: Text(_isEditingBilling ? 'SAVE' : 'EDIT',
                        style: TextStyle(fontSize: isCompact ? 8 : 9, fontWeight: FontWeight.w900)),
                  ),
            ],
          ),
          if (_isEditingBilling) ...[
            const SizedBox(height: 12),
            _buildBillingField('CARDHOLDER NAME', _cardHolderController, isCompact),
            const SizedBox(height: 12),
            Text('CARD DETAILS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            CardField(
              onCardChanged: (card) {
                // Handle card changes if needed
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            _buildBillingField('ZIP CODE', _zipController, isCompact, keyboardType: TextInputType.number),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              advisor.cardHolderName.isEmpty ? 'No card holder name' : advisor.cardHolderName.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 12 : 13),
            ),
            const SizedBox(height: 4),
            Text(
              advisor.cardNumber.isEmpty ? 'Using Stripe Secure Payment' : '•••• •••• •••• $last4',
              style: TextStyle(fontSize: isCompact ? 11 : 12, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ],
          Divider(height: isCompact ? 24 : 32),
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

  Widget _buildSendGridCard(AdvisorProvider provider, bool isCompact) {
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
              Row(
                children: [
                  Icon(Icons.email_outlined, size: isCompact ? 16 : 18, color: Colors.black54),
                  const SizedBox(width: 12),
                  Text(
                    'SENDGRID SETTINGS',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: isCompact ? 9 : 10, letterSpacing: 0.5),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  if (_isEditingSendGrid) {
                    await provider.updateSendGridSettings(
                      apiKey: _sendgridApiKeyController.text.trim(),
                      verifiedSender: _sendgridSenderController.text.trim(),
                      firmEmail: _firmEmailController.text.trim(),
                    );
                  }
                  setState(() => _isEditingSendGrid = !_isEditingSendGrid);
                },
                child: Text(_isEditingSendGrid ? 'SAVE' : 'EDIT',
                    style: TextStyle(fontSize: isCompact ? 8 : 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          if (_isEditingSendGrid) ...[
            const SizedBox(height: 12),
            _buildBillingField('SENDGRID API KEY', _sendgridApiKeyController, isCompact, obscureText: true),
            const SizedBox(height: 12),
            _buildBillingField('VERIFIED SENDER EMAIL', _sendgridSenderController, isCompact, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildBillingField('VIRTUAL FIRM EMAIL', _firmEmailController, isCompact, keyboardType: TextInputType.emailAddress),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              advisor.sendgridApiKey.isEmpty ? 'Not configured' : 'API Key: ••••••••••••',
              style: TextStyle(fontSize: isCompact ? 11 : 12, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              advisor.sendgridVerifiedSender.isEmpty ? 'No verified sender' : 'Sender: ${advisor.sendgridVerifiedSender}',
              style: TextStyle(fontSize: isCompact ? 10 : 11, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTwilioCard(AdvisorProvider provider, bool isCompact) {
    final advisor = provider.currentAdvisor!;
    final isPro = advisor.subscriptionPlan == 'Pro' || advisor.subscriptionPlan == 'Enterprise';

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
              Row(
                children: [
                  Icon(Icons.sms_outlined, size: isCompact ? 16 : 18, color: Colors.black54),
                  const SizedBox(width: 12),
                  Text(
                    'TWILIO SETTINGS',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: isCompact ? 9 : 10, letterSpacing: 0.5),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  if (_isEditingTwilio) {
                    await provider.updateTwilioSettings(
                      accountSid: _twilioSidController.text.trim(),
                      authToken: _twilioTokenController.text.trim(),
                    );
                  }
                  setState(() => _isEditingTwilio = !_isEditingTwilio);
                },
                child: Text(_isEditingTwilio ? 'SAVE' : 'EDIT',
                    style: TextStyle(fontSize: isCompact ? 8 : 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          if (_isEditingTwilio) ...[
            const SizedBox(height: 12),
            _buildBillingField('ACCOUNT SID', _twilioSidController, isCompact),
            const SizedBox(height: 12),
            _buildBillingField('AUTH TOKEN', _twilioTokenController, isCompact, obscureText: true),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              advisor.twilioAccountSid.isEmpty ? 'Not configured' : 'SID: ${advisor.twilioAccountSid}',
              style: TextStyle(fontSize: isCompact ? 11 : 12, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ],
          if (isPro && advisor.twilioAccountSid.isNotEmpty) ...[
            const Divider(height: 32),
            Text(
              'PROVISION VIRTUAL NUMBER',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: isCompact ? 8 : 9, color: Colors.grey, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            if (_availableNumbers.isEmpty && !_isSearchingNumbers)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    setState(() => _isSearchingNumbers = true);
                    try {
                      final numbers = await provider.searchTwilioNumbers();
                      setState(() => _availableNumbers = numbers);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    } finally {
                      setState(() => _isSearchingNumbers = false);
                    }
                  },
                  child: Text('SEARCH AVAILABLE NUMBERS', style: TextStyle(fontSize: isCompact ? 10 : 11, fontWeight: FontWeight.bold)),
                ),
              )
            else if (_isSearchingNumbers)
              const Center(child: CircularProgressIndicator())
            else ...[
              ..._availableNumbers.take(3).map((number) => ListTile(
                    dense: true,
                    title: Text(number, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: TextButton(
                      onPressed: () async {
                        try {
                          await provider.provisionTwilioNumber(number);
                          setState(() => _availableNumbers = []);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Number provisioned!')));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        }
                      },
                      child: const Text('PICK'),
                    ),
                  )),
              TextButton(
                onPressed: () => setState(() => _availableNumbers = []),
                child: const Text('CANCEL', style: TextStyle(fontSize: 10, color: Colors.red)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBillingField(String label, TextEditingController controller, bool isCompact, {TextInputType? keyboardType, bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(fontSize: isCompact ? 12 : 13, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }

  bool _isDownloadingModel = false;

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
            activeThumbColor: Colors.black,
            onChanged: provider.isDemoMode ? null : (val) => provider.setExpressiveAiEnabled(val),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            dense: true,
            title: Text('Multimodal AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 12 : 13)),
            subtitle: Text('Voice & images', style: TextStyle(fontSize: isCompact ? 10 : 11)),
            value: provider.isMultimodalAiEnabled,
            activeThumbColor: Colors.black,
            onChanged: provider.isDemoMode ? null : (val) => provider.setMultimodalAiEnabled(val),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          FutureBuilder<String>(
            future: provider.checkOnDeviceStatus(),
            builder: (context, snapshot) {
              final status = snapshot.data ?? 'Checking...';
              final isAvailable = status.contains('AVAILABLE') || status.contains('Ready');
              final isDownloadable = status.contains('DOWNLOADABLE') || status.contains('NeedsDownload');
              final isDownloading = status.contains('DOWNLOADING') || _isDownloadingModel;
              
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: isDownloading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Icon(
                          isAvailable ? Icons.offline_bolt : Icons.offline_bolt_outlined,
                          color: isAvailable ? Colors.green : (isDownloadable ? Colors.amber : Colors.grey),
                          size: 20,
                        ),
                    title: Text('On-Device Model', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 12 : 13)),
                    subtitle: Text(
                      isDownloading ? 'Downloading model...' : status, 
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 11, 
                        color: isAvailable ? Colors.green : (isDownloadable ? Colors.amber : null),
                      ),
                    ),
                    trailing: isDownloadable && !isDownloading
                      ? TextButton(
                          onPressed: () async {
                            setState(() => _isDownloadingModel = true);
                            try {
                              await provider.prepareOnDeviceModel();
                            } finally {
                              if (mounted) {
                                setState(() => _isDownloadingModel = false);
                              }
                            }
                          },
                          child: Text('DOWNLOAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          onPressed: () => setState(() {}),
                        ),
                  ),
                  if (isAvailable) ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      dense: true,
                      title: Text('Prefer Local AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompact ? 12 : 13)),
                      subtitle: Text('Use on-device model', style: TextStyle(fontSize: isCompact ? 10 : 11)),
                      value: provider.preferOnDeviceAi,
                      activeThumbColor: Colors.black,
                      onChanged: (val) => provider.setPreferOnDeviceAi(val),
                    ),
                  ],
                ],
              );
            },
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
        title: const Text('DELETE ACCOUNT?'),
        content: const Text('This action is permanent and will delete all your client data. Are you sure?'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: AppTheme.accentGrey, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
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
}
