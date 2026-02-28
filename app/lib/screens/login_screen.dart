import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cpa_provider.dart';
import '../models/cpa.dart';
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
    final provider = Provider.of<CpaProvider>(context);
    // Auto-navigate if already logged in via remember me
    if (provider.currentCpa != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('CPA Engagement App')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Accountant Portal',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                  ),
                  const Text('Remember Me'),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _showRegisterDialog,
                  child: const Text('New here? Register a Profile'),
                ),
                const Divider(),
                TextButton.icon(
                  onPressed: _enterDemoMode,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Review Demo Mode (No Login Required)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _enterDemoMode() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<CpaProvider>(context, listen: false);
    try {
      await provider.loginDemo();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demo mode failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<CpaProvider>(context, listen: false);
    try {
      await provider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        rememberMe: _rememberMe,
      );
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

  void _showRegisterDialog() {
    final nameController = TextEditingController();
    final firmController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isRegistering = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Register CPA Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (required)')),
                TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password (required)'), obscureText: true),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                TextField(controller: firmController, decoration: const InputDecoration(labelText: 'Firm Name')),
                if (isRegistering)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isRegistering ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isRegistering ? null : () async {
                if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email and Password are required')),
                  );
                  return;
                }

                setDialogState(() => isRegistering = true);

                try {
                  final cpa = Cpa(
                    uid: '', // Will be set by Firebase Auth
                    name: nameController.text.trim(),
                    firmName: firmController.text.trim(),
                    email: emailController.text.trim(),
                  );
                  
                  final provider = Provider.of<CpaProvider>(this.context, listen: false);
                  await provider.register(cpa, passwordController.text.trim());

                  if (mounted) {
                    Navigator.of(dialogContext).pop(); // Close dialog
                    Navigator.of(this.context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    );
                  }
                } catch (e) {
                  setDialogState(() => isRegistering = false);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Registration failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Register & Enter'),
            ),
          ],
        ),
      ),
    );
  }
}
