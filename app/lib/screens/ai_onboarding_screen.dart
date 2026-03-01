import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cpa_provider.dart';
import '../services/ai_service.dart';
import '../models/customer.dart';

class AiOnboardingScreen extends StatefulWidget {
  const AiOnboardingScreen({super.key});

  @override
  State<AiOnboardingScreen> createState() => _AiOnboardingScreenState();
}

class _AiOnboardingScreenState extends State<AiOnboardingScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  Future<void> _startConversation() async {
    setState(() => _isTyping = true);
    final provider = Provider.of<CpaProvider>(context, listen: false);
    final response = await provider.getOnboardingResponse([]);
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isTyping = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    final provider = Provider.of<CpaProvider>(context, listen: false);
    final response = await provider.getOnboardingResponse(_messages);
    
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _finalizeOnboarding() async {
    setState(() => _isTyping = true);
    final provider = Provider.of<CpaProvider>(context, listen: false);
    final customer = await provider.extractCustomerFromOnboarding(_messages);
    
    if (mounted) {
      setState(() => _isTyping = false);
      if (customer != null) {
        _showReviewDialog(customer);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to extract client details. Try adding more info.')),
        );
      }
    }
  }

  void _showReviewDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReviewField('NAME', customer.name),
              _buildReviewField('EMAIL', customer.email),
              _buildReviewField('OCCUPATION', customer.occupation),
              _buildReviewField('RULES', customer.guidelines),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<CpaProvider>(context, listen: false);
              await provider.addCustomer(customer);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close screen
              }
            },
            child: const Text('CREATE CLIENT'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? 'Not found' : value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ONBOARDING', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          if (_messages.length > 2)
            TextButton(
              onPressed: _isTyping ? null : _finalizeOnboarding,
              child: const Text('DONE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.black : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: message.isUser ? const Radius.circular(0) : const Radius.circular(12),
            bottomLeft: message.isUser ? const Radius.circular(12) : const Radius.circular(0),
          ),
          border: message.isUser ? null : Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black,
            fontSize: 14,
            height: 1.5
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12).copyWith(bottomLeft: const Radius.circular(0)),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black12),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
