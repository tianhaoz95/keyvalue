import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/feedback_item.dart';
import '../providers/admin_provider.dart';
import '../theme.dart';

class FeedbackDetailSidebar extends StatelessWidget {
  final FeedbackItem item;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const FeedbackDetailSidebar({
    super.key,
    required this.item,
    required this.onClose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
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
                  const Text('SOURCE SCREEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.screenName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _buildStatusPicker(context, Provider.of<AdminProvider>(context, listen: false)),
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
                  const SizedBox(height: 64),
                  const Divider(),
                  const SizedBox(height: 32),
                  const Text('DANGER ZONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.redAccent)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _showDeleteConfirmation(context, Provider.of<AdminProvider>(context, listen: false)),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('DELETE FEEDBACK'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
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

  Widget _buildStatusPicker(BuildContext context, AdminProvider provider) {
    final statuses = [
      {'value': 'open', 'label': 'OPEN', 'color': Colors.blueGrey},
      {'value': 'inProgress', 'label': 'IN PROGRESS', 'color': Colors.amber.shade900},
      {'value': 'resolved', 'label': 'RESOLVED', 'color': Colors.green.shade800},
      {'value': 'backlog', 'label': 'BACKLOG', 'color': Colors.grey},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((status) {
        final isSelected = item.status == status['value'];
        return GestureDetector(
          onTap: () => provider.updateFeedbackStatus(item.id, status['value'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.black : const Color(0xFFEEEEEE),
                width: 1.5,
              ),
            ),
            child: Text(
              status['label'] as String,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DELETE FEEDBACK?'),
        content: const Text('Are you sure you want to delete this feedback? This action cannot be undone.'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: AppTheme.accentGrey, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(100, 44),
                ),
                onPressed: () async {
                  await provider.deleteFeedback(item.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    onDelete();
                  }
                },
                child: const Text('DELETE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
