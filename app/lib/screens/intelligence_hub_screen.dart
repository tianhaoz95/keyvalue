import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/cpa_provider.dart';

class IntelligenceHubScreen extends StatelessWidget {
  final Customer customer;
  final Engagement engagement;

  const IntelligenceHubScreen({super.key, required this.customer, required this.engagement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Intelligence Hub: Review Suggestions')),
      body: Column(
        children: [
          // Identified Needs Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue[50],
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI-Identified Needs:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                ...engagement.pointsOfInterest.map((poi) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(child: Text(poi)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Profile Updates (Suggested):', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          
          Expanded(
            child: Row(
              children: [
                // Current Profile
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.grey[200],
                          width: double.infinity,
                          child: const Center(child: Text('Current Profile', style: TextStyle(fontSize: 12))),
                        ),
                        Expanded(child: Markdown(data: customer.details)),
                      ],
                    ),
                  ),
                ),
                // Suggested Profile
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.green[300]!)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.green[100],
                          width: double.infinity,
                          child: const Center(child: Text('Suggested Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ),
                        Expanded(child: Markdown(data: engagement.updatedDetailsDiff)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel / Keep Current'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () async {
                      final provider = Provider.of<CpaProvider>(context, listen: false);
                      await provider.approveResponse(customer, engagement);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Approve & Update'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
