import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../models/feedback_item.dart';

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
          
          // Scrim
          if (_isSidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isSidebarOpen = false),
                child: Container(color: Colors.black26),
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
                  : _buildDetailsSidebar(_selectedFeedback!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSidebar(FeedbackItem item) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const Icon(Icons.feedback_outlined, size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'FEEDBACK DETAILS',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isSidebarOpen = false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FROM ADVISOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(item.advisorName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  Text(item.advisorUid, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 32),
                  const Text('SUBMITTED AT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(DateFormat('MMMM d, yyyy • HH:mm:ss').format(item.createdAt), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 32),
                  const Text('MESSAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Text(
                      item.text,
                      style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
