import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/advisor_provider.dart';
import '../l10n/app_localizations.dart';

class EngagementTimeline extends StatefulWidget {
  final Customer customer;
  final List<Engagement> engagements;
  final AdvisorProvider provider;
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
  State<EngagementTimeline> createState() => _EngagementTimelineState();
}

class _EngagementTimelineState extends State<EngagementTimeline> {
  String? _expandedInsightEngagementId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.engagements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No engagement history yet.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.engagements.length,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      itemBuilder: (context, index) {
        final engagement = widget.engagements[index];
        final isLast = index == widget.engagements.length - 1;

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
                          Row(
                            children: [
                              Text(
                                engagement.createdAt.toLocal().toString().split(' ')[0],
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Delete Engagement',
                                onPressed: () => _showDeleteConfirmation(context, engagement),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (engagement.sentMessage.isNotEmpty)
                        _buildModernSnippet('OUTBOUND', engagement.sentMessage),
                      if (engagement.customerResponse.isNotEmpty)
                        _buildModernSnippet('INBOUND', engagement.customerResponse, isDark: true),
                      
                      if (_expandedInsightEngagementId == engagement.engagementId)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: _buildAiInsightsSection(context, engagement),
                        ),

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

  Widget _buildAiInsightsSection(BuildContext context, Engagement engagement) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_outlined, color: Colors.black, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'AI INSIGHTS',
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 10),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => widget.provider.receiveResponse(widget.customer, engagement, engagement.customerResponse),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('REGENERATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: engagement.pointsOfInterest.map((poi) => Chip(
                    label: Text(poi, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFFF9F9F9),
                    side: const BorderSide(color: Color(0xFFEEEEEE)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  )).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROPOSED PROFILE UPDATE',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: MarkdownBody(
                    data: engagement.updatedDetailsDiff,
                    styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 12, height: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                        onPressed: () => widget.provider.approveResponse(widget.customer, engagement),
                        child: const Text('APPROVE', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(80, 40),
                      ),
                      onPressed: () {
                        setState(() {
                          _expandedInsightEngagementId = null;
                        });
                      },
                      child: const Text('DISMISS', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
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
          widget.onReviewDraft?.call(engagement);
        },
        child: Text(l10n.reviewNow.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 1)),
      );
    } else if (engagement.status == EngagementStatus.received) {
      if (_expandedInsightEngagementId == engagement.engagementId) {
        return const SizedBox.shrink();
      }
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size(140, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: () {
          setState(() {
            _expandedInsightEngagementId = engagement.engagementId;
          });
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
        onPressed: () => widget.onRespond(engagement),
        child: const Text('ADD RESPONSE', style: TextStyle(fontSize: 12, letterSpacing: 1)),
      );
    }
    return const SizedBox.shrink();
  }

  void _showDeleteConfirmation(BuildContext context, Engagement engagement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Engagement?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to delete this engagement record? This action cannot be undone.'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, 
                  foregroundColor: Colors.white, 
                  elevation: 0,
                  minimumSize: const Size(100, 44),
                ),
                onPressed: () async {
                  await widget.provider.deleteEngagement(widget.customer, engagement);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engagement deleted')));
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
