import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../models/feedback_item.dart';
import '../widgets/feedback_detail_sidebar.dart';

class FeedbackListScreen extends StatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  State<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends State<FeedbackListScreen> {
  FeedbackItem? _selectedFeedback;
  bool _isSidebarOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'inProgress':
        return Colors.amber.shade900;
      case 'resolved':
        return Colors.green.shade800;
      case 'backlog':
        return Colors.grey;
      case 'open':
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;
    final sidebarWidth = isPhone ? screenWidth : 450.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FEEDBACK MANAGEMENT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => provider.logout(),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'SEARCH BY ADVISOR OR CONTENT...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<FeedbackItem>>(
                        stream: provider.getFeedbacks(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                            );
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.black));
                          }
                          
                          var feedbacks = snapshot.data ?? [];
                          
                          // Sync selected feedback with stream data to reflect status changes
                          if (_selectedFeedback != null) {
                            final updated = feedbacks.cast<FeedbackItem?>().firstWhere(
                              (item) => item?.id == _selectedFeedback!.id,
                              orElse: () => null,
                            );
                            if (updated != null && updated.status != _selectedFeedback!.status) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _selectedFeedback = updated);
                              });
                            }
                          }
                          
                          // Apply Search Filter
                          if (_searchQuery.isNotEmpty) {
                            feedbacks = feedbacks.where((item) => 
                              item.advisorName.toLowerCase().contains(_searchQuery) ||
                              item.text.toLowerCase().contains(_searchQuery)
                            ).toList();
                          }

                          if (feedbacks.isEmpty) {
                            return const Center(
                              child: Text(
                                'No matching feedback found.',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: feedbacks.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = feedbacks[index];
                              final isSelected = _selectedFeedback?.id == item.id;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                tileColor: isSelected ? Colors.black.withValues(alpha: 0.02) : null,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.advisorName,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(item.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: _getStatusColor(item.status).withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        item.status.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(item.status),
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      item.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d, y • HH:mm').format(item.createdAt),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black12),
                                onTap: () {
                                  setState(() {
                                    _selectedFeedback = item;
                                    _isSidebarOpen = true;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (!isPhone && _isSidebarOpen) SizedBox(width: sidebarWidth),
                  ],
                ),
              ),
            ],
          ),
          
          // Scrim
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isSidebarOpen,
              child: GestureDetector(
                onTap: () => setState(() => _isSidebarOpen = false),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isSidebarOpen ? 1.0 : 0.0,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),

          // Sidebar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isSidebarOpen ? 0 : -sidebarWidth,
            top: 0,
            bottom: 0,
            width: sidebarWidth,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: _selectedFeedback == null
                  ? const SizedBox.shrink()
                  : FeedbackDetailSidebar(
                      item: _selectedFeedback!,
                      onClose: () => setState(() => _isSidebarOpen = false),
                      onDelete: () => setState(() {
                        _isSidebarOpen = false;
                        _selectedFeedback = null;
                      }),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
