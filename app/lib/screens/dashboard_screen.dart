import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/cpa_provider.dart';
import '../models/customer.dart';
import '../widgets/pending_review_list.dart';
import '../widgets/loading_overlay.dart';
import 'customer_detail_screen.dart';
import 'settings_screen.dart';
import 'ai_onboarding_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CustomerSortOption _sortOption = CustomerSortOption.nextContact;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _loadSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final sortIndex = prefs.getInt('customerSortOption') ?? CustomerSortOption.nextContact.index;
    setState(() {
      _sortOption = CustomerSortOption.values[sortIndex];
    });
  }

  Future<void> _updateSortPreference(CustomerSortOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('customerSortOption', option.index);
    setState(() {
      _sortOption = option;
    });
  }

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

    // Filter and sort customers for the main list based on search and sort option
    final filteredCustomers = allCustomers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             c.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    filteredCustomers.sort((a, b) {
      if (_sortOption == CustomerSortOption.name) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else {
        return a.nextEngagementDate.compareTo(b.nextEngagementDate);
      }
    });

    return LoadingOverlay(
      isLoading: isDiscovering,
      message: 'AI Thinking...',
      child: Scaffold(
        appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: 'Search clients...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                filled: false,
              ),
            )
          : Row(
              children: [
                Image.asset('assets/images/logo_120.png', height: 28),
                const SizedBox(width: 12),
                Text(cpa.firmName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'AI Scan for Actions',
            onPressed: isDiscovering ? null : () => provider.discoverProactiveTasks(),
          ),
          PopupMenuButton<CustomerSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: _updateSortPreference,
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: CustomerSortOption.name,
                checked: _sortOption == CustomerSortOption.name,
                child: const Text('Sort by Name'),
              ),
              CheckedPopupMenuItem(
                value: CustomerSortOption.nextContact,
                checked: _sortOption == CustomerSortOption.nextContact,
                child: const Text('Sort by Next Contact'),
              ),
            ],
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            color: Colors.white,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Welcome back, ${cpa.name.split(' ')[0]}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    if (isDiscovering)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your portfolio consists of ${allCustomers.length} clients',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 24, endIndent: 24),

          // Urgent Actions Section
          if (pendingReviews.isNotEmpty) ...[
            PendingReviewList(customers: pendingReviews),
            const Divider(height: 1, indent: 24, endIndent: 24),
          ],

          const Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Text(
              'Clients',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.black54),
            ),
          ),
          
          Expanded(
            child: ListView.separated(
              itemCount: filteredCustomers.length,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final customer = filteredCustomers[index];
                return _buildCustomerTile(context, customer);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'ai_onboarding',
            elevation: 0,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AiOnboardingScreen()));
            },
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('AI ONBOARDING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add_customer',
            elevation: 0,
            onPressed: () {
              _showAddCustomerDialog(context, provider);
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black12),
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    ));
  }

  Widget _buildCustomerTile(BuildContext context, Customer customer) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Hero(
                tag: 'avatar_${customer.customerId}',
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.black12,
                  child: Text(
                    customer.name[0],
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name, 
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)
                    ),
                    Text(
                      customer.email, 
                      style: const TextStyle(fontSize: 12, color: Colors.grey)
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black12, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, CpaProvider provider) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final occupationController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
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
              TextField(controller: occupationController, decoration: const InputDecoration(labelText: 'Occupation')),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
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
                occupation: occupationController.text.trim(),
                phoneNumber: phoneController.text.trim(),
                address: addressController.text.trim(),
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
