import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cpa_provider.dart';
import '../models/customer.dart';
import 'customer_detail_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CpaProvider>(context);
    final allCustomers = provider.customers;
    final cpa = provider.currentCpa;
    final isDiscovering = provider.isDiscovering;

    if (cpa == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Filter customers with drafts for Urgent Actions
    final pendingReviews = allCustomers.where((c) => c.hasActiveDraft).toList();

    // Filter customers for the main list based on search
    final filteredCustomers = allCustomers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             c.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(cpa.firmName),
        actions: [
          if (isDiscovering)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
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
          // Welcome Header
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.blue.withValues(alpha: 0.1),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Welcome, ${cpa.name}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    if (isDiscovering)
                      const Text(
                        'AI Thinking...',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blue),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Managing ${allCustomers.length} clients',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Urgent Actions Section
          if (pendingReviews.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Pending Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pendingReviews.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final customer = pendingReviews[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Card(
                      color: Colors.redAccent.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.redAccent, width: 0.5),
                      ),
                      child: ListTile(
                        title: Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('New Draft Ready'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailScreen(customer: customer),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Your Clients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          Expanded(
            child: ListView.separated(
              itemCount: filteredCustomers.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final customer = filteredCustomers[index];
                return _buildCustomerTile(context, customer);
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

  Widget _buildCustomerTile(BuildContext context, Customer customer) {
    final healthColor = _getClientHealthColor(customer);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(child: Text(customer.name[0])),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: healthColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
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
  }

  Color _getClientHealthColor(Customer customer) {
    final now = DateTime.now();
    final daysSinceLast = now.difference(customer.lastEngagementDate).inDays;
    
    if (daysSinceLast < customer.engagementFrequencyDays) {
      return Colors.green;
    } else if (daysSinceLast < customer.engagementFrequencyDays + 7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
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
                hasActiveDraft: false,
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
