import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/advisor_provider.dart';
import '../providers/ui_context_provider.dart';
import '../models/customer.dart';

class AddClientView extends StatefulWidget {
  const AddClientView({super.key});

  @override
  State<AddClientView> createState() => _AddClientViewState();
}

class _AddClientViewState extends State<AddClientView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiContext = Provider.of<UiContextProvider>(context, listen: false);
    final advisorProvider = Provider.of<AdvisorProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => uiContext.setView(AppView.dashboard),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add New Client',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildTextField('FULL NAME', _nameController, 'Enter client name'),
              _buildTextField('EMAIL ADDRESS', _emailController, 'client@example.com', keyboardType: TextInputType.emailAddress),
              _buildTextField('PHONE NUMBER', _phoneController, '+1 (555) 000-0000', keyboardType: TextInputType.phone),
              _buildTextField('OCCUPATION', _occupationController, 'e.g. Small Business Owner'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final newCustomer = Customer(
                        customerId: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        phoneNumber: _phoneController.text.trim(),
                        occupation: _occupationController.text.trim(),
                        details: '',
                        guidelines: '',
                        engagementFrequencyDays: 30,
                        nextEngagementDate: DateTime.now(),
                        lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
                      );
                      await advisorProvider.addCustomer(newCustomer);
                      uiContext.setView(AppView.dashboard);
                    }
                  },
                  child: const Text('CREATE CLIENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.normal),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'This field is required';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
