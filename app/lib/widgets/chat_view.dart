import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'dart:convert';
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text('INTELLIGENCE HUB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                ],
              ),
              TextButton(
                onPressed: () => chatProvider.clearHistory(),
                child: const Text('CLEAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (uiContext.activeEditContext != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.05),
              border: const Border(bottom: BorderSide(color: Colors.indigo, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 14, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(
                      'EDITING ${_getLabel(uiContext.activeEditContext!.type)} CONTEXT',
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => uiContext.clearEditContext(),
                      child: const Icon(Icons.close, size: 14, color: Colors.indigo),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  uiContext.activeEditContext!.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.indigo.withOpacity(0.7),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
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
            responseBuilder: (context, message) {
              if (message.startsWith('PREVIEW_DATA:')) {
                final parts = message.split('\n');
                final previewHeader = parts[0];
                final followUpText = parts.length > 1 ? parts.sublist(1).join('\n') : "";
                
                if (!advisorProvider.isExpressiveAiEnabled) {
                  return followUpText.isNotEmpty ? MarkdownBody(data: followUpText) : const SizedBox.shrink();
                }

                try {
                  final jsonStr = previewHeader.substring(13);
                  final data = jsonDecode(jsonStr) as Map<String, dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
              return MarkdownBody(data: message);
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
}
