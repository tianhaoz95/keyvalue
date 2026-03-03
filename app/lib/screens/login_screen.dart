import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/advisor_provider.dart';
import '../models/advisor.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdvisorProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    // Auto-navigate if already logged in via remember me
    if (provider.currentAdvisor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo_cropped.png', 
                      height: 48,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'KeyValue',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Proactive intelligence for modern business advisors.',
                  style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 56),
                AutofillGroup(
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: l10n.email.toUpperCase(),
                          labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: l10n.password.toUpperCase(),
                          labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        ),
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _login(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: Colors.black,
                            onChanged: (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.rememberMe, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        l10n.forgotPassword,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.black))
                else ...[
                  ElevatedButton(
                    onPressed: _login,
                    child: Text(l10n.login.toUpperCase()),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: _showRegisterDialog,
                      child: Text(
                        l10n.createAccount,
                        style: const TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 1,
                          decoration: TextDecoration.underline,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('OR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: OutlinedButton(
                      onPressed: _enterGuestMode,
                      child: Text(l10n.continueAsGuest.toUpperCase()),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    final l10n = AppLocalizations.of(context)!;
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.resetPassword, style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.enterEmailToReset, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: l10n.email.toUpperCase()),
                keyboardType: TextInputType.emailAddress,
              ),
              if (isSending)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(color: Colors.black),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSending ? null : () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                setDialogState(() => isSending = true);
                try {
                  final provider = Provider.of<AdvisorProvider>(this.context, listen: false);
                  await provider.sendPasswordResetEmail(email);
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text(l10n.resetLinkSent)),
                    );
                  }
                } catch (e) {
                  setDialogState(() => isSending = false);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text(l10n.errorSendingReset(e.toString()))),
                    );
                  }
                }
              },
              child: Text(l10n.sendResetLink),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserAgreement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Agreement', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const SingleChildScrollView(
          child: Text(
            'By using KeyValue, you agree to the following terms:\n\n'
            '1. PROACTIVE ENGAGEMENT: KeyValue is an AI-powered tool designed to assist advisors in managing client relationships. You are responsible for reviewing and approving all AI-generated content before it is sent to clients.\n\n'
            '2. DATA ACCURACY: While we strive for high-quality AI outputs, we do not guarantee the accuracy or completeness of AI-generated suggestions or profile updates. Human oversight is mandatory.\n\n'
            '3. CONFIDENTIALITY: You agree to use KeyValue in compliance with all professional standards and regulations regarding client confidentiality.\n\n'
            '4. INTELLECTUAL PROPERTY: The KeyValue app and its underlying AI technology are the property of KeyValue. You are granted a limited license to use the tool for your professional practice.\n\n'
            '5. LIMITATION OF LIABILITY: KeyValue shall not be liable for any indirect, incidental, or consequential damages resulting from the use of the app or AI-generated content.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const SingleChildScrollView(
          child: Text(
            'KeyValue respects your privacy and the privacy of your clients.\n\n'
            '1. DATA COLLECTION: We collect advisor profile information, client details, and engagement history to provide our services.\n\n'
            '2. AI PROCESSING: Client data is processed by Google Gemini AI to generate insights and message drafts. Data is handled securely and in accordance with Firebase and Google Cloud security standards.\n\n'
            '3. SECURITY: We use industry-standard encryption and security measures to protect your data stored in Cloud Firestore and Hive.\n\n'
            '4. THIRD-PARTY SERVICES: We may use third-party services like Firebase and Twilio to provide core functionality.\n\n'
            '5. DATA OWNERSHIP: You retain ownership of your client data. We do not sell or share your data with unauthorized third parties.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  void _enterGuestMode() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<AdvisorProvider>(context, listen: false);
    try {
      await provider.loginGuest(rememberMe: _rememberMe);
      if (mounted) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Guest mode failed: $e')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<AdvisorProvider>(context, listen: false);
    try {
      await provider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        rememberMe: _rememberMe,
      );
      
      // Signal to OS that autofill is successful
      TextInput.finishAutofillContext();

      if (mounted) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: $e')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRegisterDialog() {
    final nameController = TextEditingController();
    final firmController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isRegistering = false;
    bool acceptedTerms = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Register Account', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (required)')),
                const SizedBox(height: 12),
                TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password (required)'), obscureText: true),
                const SizedBox(height: 12),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: firmController, decoration: const InputDecoration(labelText: 'Firm Name')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: acceptedTerms,
                      activeColor: Colors.black,
                      onChanged: (val) => setDialogState(() => acceptedTerms = val ?? false),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => _showUserAgreement(context),
                                child: const Text(
                                  'User Agreement',
                                  style: TextStyle(fontSize: 12, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => _showPrivacyPolicy(context),
                                child: const Text(
                                  'Privacy Policy',
                                  style: TextStyle(fontSize: 12, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isRegistering)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(color: Colors.black),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isRegistering ? null : () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: (isRegistering || !acceptedTerms) ? null : () async {
                if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email and Password are required')),
                  );
                  return;
                }

                setDialogState(() => isRegistering = true);

                try {
                  final cpa = Advisor(
                    uid: '', // Will be set by Firebase Auth
                    name: nameController.text.trim(),
                    firmName: firmController.text.trim(),
                    email: emailController.text.trim(),
                  );
                  
                  final provider = Provider.of<AdvisorProvider>(this.context, listen: false);
                  await provider.register(cpa, passwordController.text.trim());

                  if (mounted) {
                    if (context.mounted) {
                      Navigator.of(dialogContext).pop(); // Close dialog
                      Navigator.of(this.context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      );
                    }
                  }
                } catch (e) {
                  setDialogState(() => isRegistering = false);
                  if (mounted) {
                    if (this.context.mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text('Registration failed: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('REGISTER'),
            ),
          ],
        ),
      ),
    );
  }
}
