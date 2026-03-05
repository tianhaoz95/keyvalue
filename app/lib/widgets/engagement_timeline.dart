import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../providers/advisor_provider.dart';
import '../providers/ui_context_provider.dart';
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
  String? _editingDraftId;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final horizontalPadding = isCompact ? 16.0 : 24.0;

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
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
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
                    width: isCompact ? 16 : 20,
                    height: isCompact ? 16 : 20,
                    decoration: BoxDecoration(
                      color: _getStatusColor(engagement.status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: isCompact ? 6 : 8,
                        height: isCompact ? 6 : 8,
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
              SizedBox(width: isCompact ? 16 : 24),
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
                                fontSize: isCompact ? 8 : 9,
                                letterSpacing: 1,
                                color: _getStatusColor(engagement.status),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                engagement.createdAt.toLocal().toString().split(' ')[0],
                                style: TextStyle(fontSize: isCompact ? 10 : 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: isCompact ? 14 : 16, color: Colors.black26),
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
                        _buildDraftSection(context, engagement, isCompact)
                      else ...[
                        if (engagement.sentMessage.isNotEmpty)
                          _buildModernSnippet('OUTBOUND', engagement.sentMessage, Icons.outbox_outlined, isCompact: isCompact),
                        
                        if (engagement.customerResponse.isNotEmpty)
                          _buildModernSnippet('INBOUND', engagement.customerResponse, Icons.move_to_inbox_outlined, isDark: true, isCompact: isCompact),
                        
                        if (_expandedInsightEngagementId == engagement.engagementId && 
                            engagement.status == EngagementStatus.received)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: _buildAiInsightsSection(context, engagement, isCompact),
                          ),
                        
                        const SizedBox(height: 24),
                        _buildActions(context, engagement, l10n, isCompact),
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

  Widget _buildDraftSection(BuildContext context, Engagement engagement, bool isCompact) {
    final controller = _getDraftController(engagement);
    final isEditing = _editingDraftId == engagement.engagementId;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 16 : 20),
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
              Icon(Icons.auto_awesome_outlined, size: isCompact ? 14 : 16, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                'AI DRAFT READY',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: isCompact ? 9 : 10, letterSpacing: 1.5),
              ),
              const Spacer(),
              if (!isCompact) ...[
                TextButton.icon(
                  onPressed: () {
                    final uiContext = context.read<UiContextProvider>();
                    uiContext.setAiEditMode(AiEditContext(
                      type: AiEditContextType.draft,
                      content: controller.text.trim(),
                      engagementId: engagement.engagementId,
                    ));
                  },
                  icon: const Icon(Icons.auto_awesome_outlined, size: 14, color: Colors.black),
                  label: const Text(
                    'AI EDIT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 10, 
                      color: Colors.black, 
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                onPressed: () {
                  setState(() {
                    if (isEditing) {
                      _editingDraftId = null;
                      if (controller.text.trim() != engagement.draftMessage) {
                        widget.provider.updateDraft(
                          widget.customer.customerId, 
                          controller.text.trim(),
                          engagementId: engagement.engagementId,
                        );
                      }
                    } else {
                      _editingDraftId = engagement.engagementId;
                    }
                  });
                },
                icon: Icon(isEditing ? Icons.check : Icons.edit_outlined, size: isCompact ? 18 : 14, color: isEditing ? Colors.green : Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (isCompact) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                final uiContext = context.read<UiContextProvider>();
                uiContext.setAiEditMode(AiEditContext(
                  type: AiEditContextType.draft,
                  content: controller.text.trim(),
                  engagementId: engagement.engagementId,
                ));
              },
              icon: const Icon(Icons.auto_awesome_outlined, size: 12, color: Colors.black),
              label: const Text(
                'AI EDIT',
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  fontSize: 9, 
                  color: Colors.black, 
                  letterSpacing: 1.5,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: null,
            enabled: isEditing,
            style: TextStyle(
              fontSize: isCompact ? 13 : 14, 
              height: 1.6, 
              color: isEditing ? Colors.black87 : Colors.black54,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Edit draft...',
              contentPadding: EdgeInsets.zero,
              disabledBorder: InputBorder.none,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isCompact ? 120 : 140,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final message = controller.text.trim();
                    if (message != engagement.draftMessage) {
                      await widget.provider.updateDraft(
                        widget.customer.customerId, 
                        message,
                        engagementId: engagement.engagementId,
                      );
                    }
                    widget.provider.sendEngagement(widget.customer, engagement, message);
                  },
                  icon: Icon(Icons.send_outlined, size: isCompact ? 14 : 16),
                  label: Text('SEND', style: TextStyle(fontWeight: FontWeight.w900, fontSize: isCompact ? 10 : 11, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(0, isCompact ? 40 : 44),
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
                  minimumSize: Size(isCompact ? 40 : 44, isCompact ? 40 : 44),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Colors.black12, width: 1.5),
                ),
                child: Icon(Icons.copy_outlined, size: isCompact ? 16 : 18, color: Colors.black54),
              ),
              OutlinedButton(
                onPressed: () => Share.share(controller.text.trim()),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(isCompact ? 40 : 44, isCompact ? 40 : 44),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Colors.black12, width: 1.5),
                ),
                child: Icon(Icons.share_outlined, size: isCompact ? 16 : 18, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernSnippet(String label, String text, IconData icon, {bool isDark = false, bool isCompact = false}) {
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
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: isDark ? null : Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: isCompact ? 13 : 14, 
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

  Widget _buildAiInsightsSection(BuildContext context, Engagement engagement, bool isCompact) {
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
            padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_outlined, color: Colors.black, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'AI INSIGHTS',
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: isCompact ? 9 : 10),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => widget.provider.receiveResponse(widget.customer, engagement, engagement.customerResponse),
                      icon: Icon(Icons.refresh, size: isCompact ? 14 : 16),
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
                    child: Text(poi, style: TextStyle(fontSize: isCompact ? 10 : 11, fontWeight: FontWeight.w900, color: Colors.black87)),
                  )).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROPOSED PROFILE UPDATE',
                  style: TextStyle(fontSize: isCompact ? 8 : 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey),
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
                      p: TextStyle(fontSize: isCompact ? 11 : 12, height: 1.5),
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
                          minimumSize: Size(0, isCompact ? 40 : 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          widget.provider.approveResponse(widget.customer, engagement);
                          setState(() {
                            _expandedInsightEngagementId = null;
                          });
                        },
                        child: Text('APPROVE UPDATE', style: TextStyle(fontSize: isCompact ? 10 : 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(isCompact ? 80 : 100, isCompact ? 40 : 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                      onPressed: () {
                        widget.provider.dismissResponse(widget.customer, engagement);
                        setState(() {
                          _expandedInsightEngagementId = null;
                        });
                      },
                      child: Text('DISMISS', style: TextStyle(fontSize: isCompact ? 10 : 11, fontWeight: FontWeight.w900, color: Colors.grey)),
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

  Widget _buildActions(BuildContext context, Engagement engagement, AppLocalizations l10n, bool isCompact) {
    if (engagement.status == EngagementStatus.received) {
      if (_expandedInsightEngagementId == engagement.engagementId) {
        return const SizedBox.shrink();
      }
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: Size(isCompact ? 160 : 180, isCompact ? 40 : 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(Icons.auto_awesome_outlined, size: isCompact ? 16 : 18),
        onPressed: () {
          setState(() {
            _expandedInsightEngagementId = engagement.engagementId;
          });
        },
        label: Text('VIEW AI INSIGHTS', style: TextStyle(fontSize: isCompact ? 11 : 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      );
    } else if (engagement.status == EngagementStatus.sent) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(isCompact ? 160 : 180, isCompact ? 40 : 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: const BorderSide(color: Colors.black, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(Icons.add_comment_outlined, size: isCompact ? 16 : 18),
        onPressed: () => widget.onRespond(engagement),
        label: Text('ADD RESPONSE', style: TextStyle(fontSize: isCompact ? 11 : 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.black)),
      );
    }
    return const SizedBox.shrink();
  }

  void _showDeleteConfirmation(BuildContext context, Engagement engagement) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Engagement?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to delete this engagement record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
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
              // Unfocus to prevent SelectionContainer errors
              FocusManager.instance.primaryFocus?.unfocus();
              // Allow one frame for the focus change to propagate
              await Future.delayed(Duration.zero);
              
              if (!context.mounted) return;
              
              await widget.provider.deleteEngagement(widget.customer, engagement);
              
              if (context.mounted) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogContext);
                messenger.showSnackBar(const SnackBar(content: Text('Engagement deleted')));
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
