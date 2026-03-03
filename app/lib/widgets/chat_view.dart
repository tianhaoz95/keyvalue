import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'dart:convert';
import '../services/chat_provider.dart';
import '../providers/cpa_provider.dart';

class KeyValueChatView extends StatelessWidget {
  final KeyValueChatProvider provider;

  const KeyValueChatView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final cpaProvider = Provider.of<CpaProvider>(context);
    
    return LlmChatView(
      provider: provider,
      responseBuilder: (context, message) {
        if (message.startsWith('PREVIEW_DATA:')) {
          final parts = message.split('\n');
          final previewHeader = parts[0];
          final followUpText = parts.length > 1 ? parts.sublist(1).join('\n') : "";
          
          if (!cpaProvider.isExpressiveAiEnabled) {
            return followUpText.isNotEmpty ? MarkdownBody(data: followUpText) : const SizedBox.shrink();
          }

          try {
            final jsonStr = previewHeader.substring(13);
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClientInfoCard(context, data),
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
    );
  }

  Widget _buildClientInfoCard(BuildContext context, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_search_outlined, size: 20, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                'CLIENT PREVIEW',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('NAME', data['name'] ?? '-'),
          _buildInfoRow('EMAIL', data['email'] ?? '-'),
          _buildInfoRow('OCCUPATION', data['occupation'] ?? '-'),
          if (data['details'] != null && data['details'].toString().isNotEmpty)
            _buildInfoRow('BACKGROUND', 'Available', isMarkdown: true, content: data['details']),
          if (data['guidelines'] != null && data['guidelines'].toString().isNotEmpty)
            _buildInfoRow('GUIDELINES', 'Available', isMarkdown: true, content: data['guidelines']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMarkdown = false, String? content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          if (isMarkdown && content != null)
             const Icon(Icons.check_circle, size: 14, color: Colors.green)
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
