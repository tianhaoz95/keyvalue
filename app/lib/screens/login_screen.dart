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
  final _uidController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
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
                controller: _uidController,
                decoration: const InputDecoration(
                  labelText: 'CPA UID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
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
    final provider = Provider.of<CpaProvider>(context, listen: false);
    final demoCpa = Cpa(
      uid: 'demo_user',
      name: 'Demo Accountant',
      firmName: 'Sample Firm LLC',
      email: 'demo@example.com',
    );
    await provider.register(demoCpa);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (_uidController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<CpaProvider>(context, listen: false);
    await provider.login(_uidController.text);
    setState(() => _isLoading = false);

    if (mounted) {
      if (provider.currentCpa != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not found. Please register.')),
        );
      }
    }
  }

  void _showRegisterDialog() {
    final nameController = TextEditingController();
    final firmController = TextEditingController();
    final emailController = TextEditingController();
    final uidController = TextEditingController();
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
                TextField(controller: uidController, decoration: const InputDecoration(labelText: 'Preferred UID (required)')),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                TextField(controller: firmController, decoration: const InputDecoration(labelText: 'Firm Name')),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email Address')),
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
                if (uidController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('UID is required')),
                  );
                  return;
                }

                setDialogState(() => isRegistering = true);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Starting registration...'), duration: Duration(seconds: 1)),
                  );
                }

                try {
                  final cpa = Cpa(
                    uid: uidController.text.trim(),
                    name: nameController.text.trim(),
                    firmName: firmController.text.trim(),
                    email: emailController.text.trim(),
                  );
                  
                  // Use the outer context's provider to avoid route issues
                  final provider = Provider.of<CpaProvider>(this.context, listen: false);
                  await provider.register(cpa);

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
