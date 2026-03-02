import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../services/chat_provider.dart';

class KeyValueChatView extends StatelessWidget {
  final KeyValueChatProvider provider;

  const KeyValueChatView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return LlmChatView(
      provider: provider,
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
    );
  }
}
