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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: Card(child: Padding(padding: const EdgeInsets.all(8.0), child: Markdown(data: widget.customer.details))),
            ),
            const SizedBox(height: 16),
            const Text('Draft Message:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _messageController,
              maxLines: 10,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final provider = Provider.of<CpaProvider>(context, listen: false);
                  await provider.sendEngagement(widget.customer, widget.engagement, _messageController.text);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Send Message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
