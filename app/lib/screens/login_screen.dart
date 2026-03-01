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
      backgroundColor: Colors.white,
      body: Center(
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
                'Proactive intelligence for modern accountants.',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 56),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'EMAIL',
                  labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'PASSWORD',
                  labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
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
                  const Text('Remember me', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.black))
              else ...[
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('LOGIN'),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: _showRegisterDialog,
                    child: const Text(
                      'CREATE AN ACCOUNT',
                      style: TextStyle(
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
                    child: const Text('CONTINUE AS GUEST'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _enterGuestMode() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<CpaProvider>(context, listen: false);
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
    final provider = Provider.of<CpaProvider>(context, listen: false);
    try {
      await provider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        rememberMe: _rememberMe,
      );
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
