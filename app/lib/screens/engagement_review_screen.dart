import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/cpa_provider.dart';

class EngagementReviewScreen extends StatefulWidget {
  final Customer customer;
  final Engagement engagement;

  const EngagementReviewScreen({super.key, required this.customer, required this.engagement});

  @override
  State<EngagementReviewScreen> createState() => _EngagementReviewScreenState();
}

class _EngagementReviewScreenState extends State<EngagementReviewScreen> {
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.engagement.draftMessage);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Engagement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text('CLIENT CONTEXT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                child: Padding(padding: const EdgeInsets.all(12.0), child: Markdown(data: widget.customer.details)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.edit_note, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text('ENGAGEMENT DRAFT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Refine your message...',
                fillColor: Colors.blue.withValues(alpha: 0.02),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _sendMessage(context),
              child: const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context) async {
    final provider = Provider.of<CpaProvider>(context, listen: false);
    final message = _messageController.text;
    
    // Store original states for Undo if needed
    // (In a real app, Undo for 'sent' might mean 'unsend' or 'mark as draft again')
    
    await provider.sendEngagement(widget.customer, widget.engagement, message);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent to client'),
          duration: Duration(seconds: 4),
          // Action for Undo could be implemented if CpaProvider supported it
        ),
      );
    }
  }
}
