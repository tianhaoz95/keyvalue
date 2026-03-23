import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'dart:convert';
import '../models/engagement.dart';
import '../providers/advisor_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/ui_context_provider.dart';
import 'ai/embedded_client_card.dart';

class KeyValueChatView extends StatelessWidget {
  final LlmProvider provider;

  const KeyValueChatView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final advisorProvider = Provider.of<AdvisorProvider>(context);
    final chatProvider = provider as GlobalChatProvider;
    final uiContext = Provider.of<UiContextProvider>(context);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isMobile)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                      onPressed: () => uiContext.setSidebarExpanded(false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (isMobile) const SizedBox(width: 12),
                  const Icon(Icons.auto_awesome_outlined, size: 16),
                  const SizedBox(width: 8),
                  const Text('INTELLIGENCE HUB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => chatProvider.clearHistory(),
                    child: const Text('CLEAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  if (!isMobile)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                      onPressed: () => uiContext.setSidebarExpanded(false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (uiContext.activeEditContext != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_outlined, size: 10, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            '${_getLabel(uiContext.activeEditContext!.type)} CONTEXT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 8,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => uiContext.clearEditContext(),
                      icon: const Icon(Icons.close, size: 14, color: Colors.black54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Text(
                    uiContext.activeEditContext!.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: LlmChatView(
            provider: provider,
            enableAttachments: advisorProvider.isMultimodalAiEnabled,
            enableVoiceNotes: advisorProvider.isMultimodalAiEnabled,
            speechToText: advisorProvider.aiService.transcribeAudio,
            responseBuilder: (context, message) {
              AiSource source = AiSource.unknown;
              String displayMessage = message;
              
              if (message.startsWith('AI_SOURCE:')) {
                final lines = message.split('\n');
                final sourceStr = lines[0].substring(10);
                try {
                  source = AiSource.values.byName(sourceStr);
                } catch (_) {}
                displayMessage = lines.length > 1 ? lines.sublist(1).join('\n') : "";
              }

              if (displayMessage.startsWith('PREVIEW_DATA:')) {
                final parts = displayMessage.split('\n');
                final previewHeader = parts[0];
                final followUpText = parts.length > 1 ? parts.sublist(1).join('\n') : "";
                
                if (!advisorProvider.isExpressiveAiEnabled) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (source != AiSource.unknown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildSourceIndicator(source, isMobile),
                        ),
                      followUpText.isNotEmpty ? MarkdownBody(data: followUpText) : const SizedBox.shrink(),
                    ],
                  );
                }

                try {
                  final jsonStr = previewHeader.substring(13);
                  final data = jsonDecode(jsonStr) as Map<String, dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (source != AiSource.unknown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildSourceIndicator(source, isMobile),
                        ),
                      EmbeddedClientCard(data: data),
                      if (followUpText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: MarkdownBody(data: followUpText),
                        ),
                    ],
                  );
                } catch (e) {
                  return Text("Error parsing preview: $e");
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (source != AiSource.unknown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildSourceIndicator(source, isMobile),
                    ),
                  MarkdownBody(data: displayMessage),
                ],
              );
            },
            style: LlmChatViewStyle(
              backgroundColor: Colors.white,
              messageSpacing: 16,
              padding: const EdgeInsets.all(24),
              progressIndicatorColor: Colors.black12,
              userMessageStyle: UserMessageStyle(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12).copyWith(
                    bottomRight: const Radius.circular(0),
                  ),
                ),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              llmMessageStyle: LlmMessageStyle(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12).copyWith(
                    bottomLeft: const Radius.circular(0),
                  ),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                markdownStyle: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              chatInputStyle: ChatInputStyle(
                backgroundColor: Colors.white,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                textStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                hintText: 'Type message...',
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getLabel(AiEditContextType type) {
    switch (type) {
      case AiEditContextType.draft:
        return 'DRAFT';
      case AiEditContextType.profile:
        return 'PROFILE';
      case AiEditContextType.guidelines:
        return 'GUIDELINES';
    }
  }

  Widget _buildSourceIndicator(AiSource source, bool isMobile) {
    String label;
    IconData icon;
    Color color;

    switch (source) {
      case AiSource.onDevice:
        label = kIsWeb ? 'BROWSER' : 'ON-DEVICE';
        icon = kIsWeb ? Icons.browser_updated : Icons.phonelink_setup;
        color = Colors.green;
        break;
      case AiSource.cloud:
        label = 'CLOUD';
        icon = Icons.cloud_outlined;
        color = Colors.blue;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
