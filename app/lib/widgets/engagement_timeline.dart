import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/advisor_provider.dart';
import '../l10n/app_localizations.dart';

class EngagementTimeline extends StatefulWidget {
  final Customer customer;
  final List<Engagement> engagements;
  final AdvisorProvider provider;
  final Function(Engagement) onRespond;

  const EngagementTimeline({
    super.key,
    required this.customer,
    required this.engagements,
    required this.provider,
    required this.onRespond,
  });

  @override
  State<EngagementTimeline> createState() => _EngagementTimelineState();
}

class _EngagementTimelineState extends State<EngagementTimeline> {
  String? _expandedInsightEngagementId;
  final Map<String, TextEditingController> _draftControllers = {};

  @override
  void dispose() {
    for (var controller in _draftControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getDraftController(Engagement engagement) {
    if (!_draftControllers.containsKey(engagement.engagementId)) {
      _draftControllers[engagement.engagementId] = TextEditingController(text: engagement.draftMessage);
    }
    return _draftControllers[engagement.engagementId]!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.engagements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No engagement history yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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
          key: ValueKey(engagement.engagementId),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Enhanced timeline visuals
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getStatusColor(engagement.status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(engagement.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isLast ? Colors.transparent : Colors.black.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(engagement.status).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusLabel(engagement.status, l10n),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                letterSpacing: 1,
                                color: _getStatusColor(engagement.status),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                engagement.createdAt.toLocal().toString().split(' ')[0],
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.black26),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Delete Engagement',
                                onPressed: () => _showDeleteConfirmation(context, engagement),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Handle DRAFT status differently: show editable content
                      if (engagement.status == EngagementStatus.draft)
                        _buildDraftSection(context, engagement)
                      else ...[
                        if (engagement.sentMessage.isNotEmpty)
                          _buildModernSnippet('OUTBOUND', engagement.sentMessage, Icons.outbox_outlined),
                        
                        if (engagement.customerResponse.isNotEmpty)
                          _buildModernSnippet('INBOUND', engagement.customerResponse, Icons.move_to_inbox_outlined, isDark: true),
                        
                        if (_expandedInsightEngagementId == engagement.engagementId && 
                            engagement.status == EngagementStatus.received)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: _buildAiInsightsSection(context, engagement),
                          ),
                        
                        const SizedBox(height: 24),
                        _buildActions(context, engagement, l10n),
                      ],
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

  Widget _buildDraftSection(BuildContext context, Engagement engagement) {
    final controller = _getDraftController(engagement);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 16, color: Colors.black),
              const SizedBox(width: 8),
              const Text(
                'AI DRAFT READY',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
              ),
              const Spacer(),
              const Text(
                'EDITABLE',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 8, color: Colors.grey, letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: null,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Edit draft...',
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 140,
                child: ElevatedButton.icon(
                  onPressed: () => widget.provider.sendEngagement(widget.customer, engagement, controller.text.trim()),
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('SEND', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.text.trim()));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Colors.black12, width: 1.5),
                ),
                child: const Icon(Icons.copy_outlined, size: 18, color: Colors.black54),
              ),
              OutlinedButton(
                onPressed: () => Share.share(controller.text.trim()),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Colors.black12, width: 1.5),
                ),
                child: const Icon(Icons.share_outlined, size: 18, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernSnippet(String label, String text, IconData icon, {bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.grey),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: isDark ? null : Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14, 
                height: 1.6, 
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: isDark ? FontWeight.w500 : FontWeight.w400,
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
        border: Border.all(color: Colors.black, width: 1),
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
                    IconButton(
                      onPressed: () => widget.provider.receiveResponse(widget.customer, engagement, engagement.customerResponse),
                      icon: const Icon(Icons.refresh, size: 16),
                      tooltip: 'Regenerate Insights',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: engagement.pointsOfInterest.map((poi) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(poi, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black87)),
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
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: MarkdownBody(
                    data: engagement.updatedDetailsDiff,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          widget.provider.approveResponse(widget.customer, engagement);
                          setState(() {
                            _expandedInsightEngagementId = null;
                          });
                        },
                        child: const Text('APPROVE UPDATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(100, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                      onPressed: () {
                        widget.provider.dismissResponse(widget.customer, engagement);
                        setState(() {
                          _expandedInsightEngagementId = null;
                        });
                      },
                      child: const Text('DISMISS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey)),
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
    if (engagement.status == EngagementStatus.received) {
      if (_expandedInsightEngagementId == engagement.engagementId) {
        return const SizedBox.shrink();
      }
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size(180, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.auto_awesome_outlined, size: 18),
        onPressed: () {
          setState(() {
            _expandedInsightEngagementId = engagement.engagementId;
          });
        },
        label: const Text('VIEW AI INSIGHTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      );
    } else if (engagement.status == EngagementStatus.sent) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(180, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: const BorderSide(color: Colors.black, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.add_comment_outlined, size: 18),
        onPressed: () => widget.onRespond(engagement),
        label: const Text('ADD RESPONSE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.black)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Engagement?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to delete this engagement record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 11)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, 
              foregroundColor: Colors.white, 
              elevation: 0,
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await widget.provider.deleteEngagement(widget.customer, engagement);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engagement deleted')));
              }
            },
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(EngagementStatus status) {
    switch (status) {
      case EngagementStatus.draft: return Colors.amber;
      case EngagementStatus.sent: return Colors.blueGrey;
      case EngagementStatus.received: return Colors.black;
      case EngagementStatus.completed: return Colors.grey;
      default: return Colors.black;
    }
  }

  String _getStatusLabel(EngagementStatus status, AppLocalizations l10n) {
    switch (status) {
      case EngagementStatus.draft: return 'PENDING DRAFT';
      case EngagementStatus.sent: return 'OUTBOUND SENT';
      case EngagementStatus.received: return 'INBOUND RECEIVED';
      case EngagementStatus.completed: return 'COMPLETED';
      default: return 'ENGAGEMENT';
    }
  }
}
