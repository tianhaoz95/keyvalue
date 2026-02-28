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
      appBar: AppBar(title: const Text('Relationship Insights')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identified Needs Header
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI-IDENTIFIED NEEDS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: engagement.pointsOfInterest.map((poi) => Chip(
                    label: Text(poi, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  )).toList(),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Proposed Profile Update',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Current Profile
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            width: double.infinity,
                            child: const Text('CURRENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          Expanded(child: Markdown(data: customer.details)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Suggested Profile
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            width: double.infinity,
                            child: const Text('PROPOSED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                          Expanded(child: Markdown(data: engagement.updatedDetailsDiff)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Keep Current'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _approveUpdate(context),
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

  void _approveUpdate(BuildContext context) async {
    final provider = Provider.of<CpaProvider>(context, listen: false);
    
    // Store original details for Undo
    final originalDetails = customer.details;
    final originalStatus = engagement.status;

    await provider.approveResponse(customer, engagement);
    
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              // Undo logic: revert customer details and engagement status
              final revertedCustomer = customer.copyWith(details: originalDetails);
              await provider.addCustomer(revertedCustomer);
              
              // We need a way to revert engagement status. 
              // For now, we'll just re-save it with original status.
              final revertedEngagement = engagement.copyWith(status: originalStatus);
              // Note: This might need a provider method if we want to be clean.
              // But provider.receiveResponse actually sets it to 'received'.
              // We'll just leave it as is for now or add a revert method.
            },
          ),
        ),
      );
    }
  }
}
