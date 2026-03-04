import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:feedback/feedback.dart';
import '../providers/advisor_provider.dart';
import '../models/advisor.dart';
import '../constants/legal_content.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _firmController = TextEditingController();
  
  bool _isLoading = false;
  bool _acceptedTerms = false;
  
  String? _legalSidebarContent;
  String? _legalSidebarTitle;
  bool _isLegalSidebarOpen = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _firmController.dispose();
    super.dispose();
  }

  void _showLegalSidebar(String title, String content) {
    setState(() {
      _legalSidebarTitle = title;
      _legalSidebarContent = content;
      _isLegalSidebarOpen = true;
    });
  }

  Future<void> _register() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and Password are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final advisor = Advisor(
        uid: '', // Set by Firebase Auth
        name: _nameController.text.trim(),
        firmName: _firmController.text.trim(),
        email: _emailController.text.trim(),
      );
      
      final provider = Provider.of<AdvisorProvider>(context, listen: false);
      await provider.register(advisor, _passwordController.text.trim());

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {
              BetterFeedback.of(context).show((feedback) {
                context.read<AdvisorProvider>().submitFeedback(feedback.text, 'REGISTER');
              });
            },
            icon: const Icon(Icons.feedback_outlined, color: Colors.black),
            tooltip: 'Send Feedback',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Join the next generation of proactive advisors.',
                      style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email (required)'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password (required)'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _firmController,
                      decoration: const InputDecoration(labelText: 'Business Name'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          activeColor: Colors.black,
                          onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: Colors.black, height: 1.4),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () => _showLegalSidebar('User Agreement', LegalContent.userAgreement),
                                    child: const Text(
                                      'User Agreement',
                                      style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                    ),
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () => _showLegalSidebar('Privacy Policy', LegalContent.privacyPolicy),
                                    child: const Text(
                                      'Privacy Policy',
                                      style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_acceptedTerms) ? null : _register,
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('CREATE ACCOUNT'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Legal Sidebar
          if (_isLegalSidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isLegalSidebarOpen = false),
                child: Container(color: Colors.black26),
              ),
            ),
          
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isLegalSidebarOpen ? 0 : -450,
            top: 0,
            bottom: 0,
            child: Container(
              width: 450,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _legalSidebarTitle ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _isLegalSidebarOpen = false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: MarkdownBody(
                          data: _legalSidebarContent ?? '',
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 14, height: 1.6),
                            h3: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
