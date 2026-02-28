import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cpa_provider.dart';
import '../models/customer.dart';
import '../widgets/pending_review_list.dart';
import '../widgets/search_field.dart';
import '../widgets/loading_overlay.dart';
import 'customer_detail_screen.dart';
import 'settings_screen.dart';

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

    return LoadingOverlay(
      isLoading: isDiscovering,
      message: 'AI Thinking...',
      child: Scaffold(
        appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo_120.png', height: 32),
            const SizedBox(width: 8),
            Text(cpa.firmName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                      Text(
                        'AI Thinking...',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).primaryColor,
                        ),
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
          PendingReviewList(customers: pendingReviews),

          // Search Bar
          SearchField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
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
              separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    ));
  }

  Widget _buildCustomerTile(BuildContext context, Customer customer) {
    final healthColor = _getClientHealthColor(customer);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Hero(
          tag: 'avatar_${customer.customerId}',
          child: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Text(
                  customer.name[0],
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: healthColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.email, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              'Next contact: ${customer.nextEngagementDate.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
              const SizedBox(height: 12),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Details (Markdown)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: guidelinesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Engagement Guidelines (Markdown)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
            onPressed: () async {
              if (nameController.text.isEmpty || emailController.text.isEmpty) return;
              final customer = Customer(
                customerId: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                email: emailController.text.trim(),
                details: detailsController.text.trim(),
                guidelines: guidelinesController.text.trim(),
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
