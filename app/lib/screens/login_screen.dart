import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:feedback/feedback.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/advisor_provider.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              BetterFeedback.of(context).show((feedback) {
                context.read<AdvisorProvider>().submitFeedback(feedback.text, 'LOGIN');
              });
            },
            icon: const Icon(Icons.feedback_outlined, color: Colors.black),
            tooltip: 'Send Feedback',
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: Text(l10n.login.toUpperCase()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
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

  void _enterGuestMode() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<AdvisorProvider>(context, listen: false);
    try {
      await provider.loginGuest(rememberMe: _rememberMe);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guest mode failed: $e')),
        );
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  final provider = Provider.of<AdvisorProvider>(context, listen: false);
                  await provider.sendPasswordResetEmail(email);
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.resetLinkSent)),
                    );
                  }
                } catch (e) {
                  setDialogState(() => isSending = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
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
}
