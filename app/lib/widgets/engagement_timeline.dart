import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/cpa_provider.dart';
import '../l10n/app_localizations.dart';

class EngagementTimeline extends StatelessWidget {
  final Customer customer;
  final List<Engagement> engagements;
  final CpaProvider provider;
  final Function(Engagement) onRespond;
  final Function(Engagement)? onReviewDraft;

  const EngagementTimeline({
    super.key,
    required this.customer,
    required this.engagements,
    required this.provider,
    required this.onRespond,
    this.onReviewDraft,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (engagements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No engagement history yet.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      itemCount: engagements.length,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      itemBuilder: (context, index) {
        final engagement = engagements[index];
        final isLast = index == engagements.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modern minimalist timeline
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(engagement.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 1,
                      color: isLast ? Colors.transparent : Colors.black12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getStatusLabel(engagement.status, l10n),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            engagement.createdAt.toLocal().toString().split(' ')[0],
                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (engagement.sentMessage.isNotEmpty)
                        _buildModernSnippet('OUTBOUND', engagement.sentMessage),
                      if (engagement.customerResponse.isNotEmpty)
                        _buildModernSnippet('INBOUND', engagement.customerResponse, isDark: true),
                      if (engagement.status == EngagementStatus.draft)
                        const Text(
                          'A proactive outreach draft is prepared and waiting for your final approval.',
                          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                        ),
                      const SizedBox(height: 20),
                      _buildActions(context, engagement, l10n),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernSnippet(String label, String text, {bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(8),
              border: isDark ? null : Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13, 
                height: 1.5, 
                color: isDark ? Colors.white : Colors.black87
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Engagement engagement, AppLocalizations l10n) {
    if (engagement.status == EngagementStatus.draft) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(140, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: () {
          // The CustomerDetailScreen handles the sidebar logic.
          // Since this widget is inside that screen, we can use a callback 
          // or just trigger the parent state if possible. 
          // However, simpler is to add a callback to EngagementTimeline.
          onReviewDraft?.call(engagement);
        },
        child: Text(l10n.reviewNow.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 1)),
      );
    } else if (engagement.status == EngagementStatus.received) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size(140, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: () {
          DefaultTabController.of(context).animateTo(0);
        },
        child: const Text('VIEW AI INSIGHTS', style: TextStyle(fontSize: 12, letterSpacing: 1)),
      );
    } else if (engagement.status == EngagementStatus.sent) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(140, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        onPressed: () => onRespond(engagement),
        child: const Text('ADD RESPONSE', style: TextStyle(fontSize: 12, letterSpacing: 1)),
      );
    }
    return const SizedBox.shrink();
  }

  Color _getStatusColor(EngagementStatus status) {
    switch (status) {
      case EngagementStatus.draft: return Colors.black26;
      case EngagementStatus.sent: return Colors.black45;
      case EngagementStatus.received: return Colors.black;
      case EngagementStatus.completed: return Colors.black12;
      default: return Colors.black;
    }
  }

  String _getStatusLabel(EngagementStatus status, AppLocalizations l10n) {
    switch (status) {
      case EngagementStatus.draft: return l10n.pendingActions.toUpperCase();
      case EngagementStatus.sent: return 'OUTBOUND SENT';
      case EngagementStatus.received: return 'INBOUND RECEIVED';
      case EngagementStatus.completed: return 'COMPLETED';
      default: return 'ENGAGEMENT';
    }
  }
}
