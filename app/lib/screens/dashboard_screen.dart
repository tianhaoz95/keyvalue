import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cpa_provider.dart';
import '../models/customer.dart';
import 'customer_detail_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CpaProvider>(context);
    final customers = provider.customers;
    final cpa = provider.currentCpa;

    if (cpa == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(cpa.firmName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                _showEditProfileDialog(context, provider);
              } else if (value == 'delete') {
                _showDeleteAccountDialog(context, provider);
              } else if (value == 'logout') {
                provider.logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Modify Profile')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Account', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.blue.withValues(alpha: 0.1),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${cpa.name}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Managing ${customers.length} clients',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Your Clients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: customers.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading: CircleAvatar(child: Text(customer.name[0])),
                    title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Next contact: ${customer.nextEngagementDate.toLocal().toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerDetailScreen(customer: customer),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCustomerDialog(context, provider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, CpaProvider provider) {
    final cpa = provider.currentCpa!;
    final nameController = TextEditingController(text: cpa.name);
    final firmController = TextEditingController(text: cpa.firmName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modify Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: firmController, decoration: const InputDecoration(labelText: 'Firm Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updatedCpa = cpa.copyWith(
                name: nameController.text.trim(),
                firmName: firmController.text.trim(),
              );
              await provider.updateProfile(updatedCpa);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, CpaProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action cannot be undone. All your data will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await provider.deleteAccount();
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, CpaProvider provider) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final detailsController = TextEditingController();
    final guidelinesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: detailsController, maxLines: 3, decoration: const InputDecoration(labelText: 'Details (Markdown)')),
              TextField(controller: guidelinesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Engagement Guidelines (Markdown)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final customer = Customer(
                customerId: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                email: emailController.text,
                details: detailsController.text,
                guidelines: guidelinesController.text,
                engagementFrequencyDays: 30,
                nextEngagementDate: DateTime.now(), // Trigger proactive discovery immediately
                lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
              );
              await provider.addCustomer(customer);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
