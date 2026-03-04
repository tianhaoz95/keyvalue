import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../providers/advisor_provider.dart';
import '../providers/ui_context_provider.dart';
import '../models/customer.dart';
import '../widgets/pending_review_list.dart';
import '../widgets/loading_overlay.dart';
import '../l10n/app_localizations.dart';

enum CustomerSortOption { nextContact, name }

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
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
    final provider = Provider.of<AdvisorProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final allCustomers = provider.customers;
    final cpa = provider.currentAdvisor;
    final isDiscovering = provider.isDiscovering;

    if (cpa == null) return const Center(child: CircularProgressIndicator());

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
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (provider.isGuestMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                    color: Colors.amber.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'DEMO MODE: AI features are disabled. Please register for full access.',
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.amber.shade900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Welcome Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 12.0),
                  color: Colors.white,
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l10n.welcomeBack}, ${cpa.name.split(' ')[0]}',
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
                    ],
                  ),
                ),

                // Urgent Actions Section
                if (pendingReviews.isNotEmpty) ...[
                  PendingReviewList(customers: pendingReviews),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 12, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          l10n.clients,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.black54),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: _isSearching ? 200 : 0,
                              height: 36,
                              margin: EdgeInsets.symmetric(horizontal: _isSearching ? 12.0 : 0),
                              child: ClipRect(
                                child: SizedBox(
                                  width: 200,
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    textAlign: TextAlign.left,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      hintText: 'Search...',
                                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.04),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isSearching ? Icons.close : Icons.search_outlined, size: 20, color: Colors.black54),
                          onPressed: () {
                            setState(() {
                              if (_isSearching) {
                                _isSearching = false;
                                _searchController.clear();
                                _searchQuery = '';
                              } else {
                                _isSearching = true;
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_add_alt_1_outlined, size: 20, color: Colors.black54),
                          tooltip: 'Add New Client',
                          onPressed: () {
                            context.read<UiContextProvider>().setView(AppView.addClient);
                          },
                        ),
                        PopupMenuButton<CustomerSortOption>(
                          icon: const Icon(Icons.sort_outlined, size: 20, color: Colors.black54),
                          tooltip: 'Sort Clients',
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
                      ],
                    ),
                  ),
                ),
                
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCustomers.length,
                  padding: const EdgeInsets.only(bottom: 100),
                  separatorBuilder: (_, index) => const Divider(height: 1, indent: 24, endIndent: 24),
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return _buildCustomerTile(context, customer);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTile(BuildContext context, Customer customer) {
    return InkWell(
      onTap: () {
        context.read<UiContextProvider>().setView(
          AppView.customerDetail,
          customerId: customer.customerId,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'NEXT CONTACT',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, y').format(customer.nextEngagementDate),
                  style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w700),
                ),
                const Icon(Icons.chevron_right, color: Colors.black12, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
