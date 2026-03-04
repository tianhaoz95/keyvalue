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
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<FeedbackItem>>(
                  stream: provider.getFeedbacks(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading feedback: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => setState(() {}),
                                child: const Text('RETRY'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.black));
                    }
                    final feedbacks = snapshot.data ?? [];
                    if (feedbacks.isEmpty) {
                      return const Center(
                        child: Text(
                          'No feedback submitted yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: feedbacks.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = feedbacks[index];
                        final isSelected = _selectedFeedback?.id == item.id;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          tileColor: isSelected ? Colors.black.withValues(alpha: 0.02) : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text(
                            item.advisorName,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
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
          
          // Scrim (Transparent as per style guide)
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
