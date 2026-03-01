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
      appBar: AppBar(
        title: const Text('REVIEW DRAFT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CLIENT CONTEXT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: MarkdownBody(data: widget.customer.details),
            ),
            const SizedBox(height: 48),
            const Text('MESSAGE DRAFT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: 'Refine your message...',
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _sendMessage(context),
              child: const Text('SEND TO CLIENT'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context) async {
    final provider = Provider.of<CpaProvider>(context, listen: false);
    final message = _messageController.text;
    
    await provider.sendEngagement(widget.customer, widget.engagement, message);
    
    if (mounted) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully'),
            backgroundColor: Colors.black,
          ),
        );
      }
    }
  }
}
