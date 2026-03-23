import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:keyvalue_app/widgets/chat_view.dart';
import 'package:keyvalue_app/providers/advisor_provider.dart';
import 'package:keyvalue_app/providers/chat_provider.dart';
import 'package:keyvalue_app/providers/ui_context_provider.dart';
import 'package:keyvalue_app/models/customer.dart';
import 'dart:convert';

class MockLlmProvider extends ChangeNotifier implements LlmProvider {
  List<ChatMessage> _history = [];

  @override
  Iterable<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> history) {
    _history = history.toList();
    notifyListeners();
  }

  @override
  Stream<String> generateStream(String prompt, {Iterable<Attachment> attachments = const []}) {
    return Stream.value("Mock response to: $prompt");
  }

  @override
  Stream<String> sendMessageStream(String prompt, {Iterable<Attachment> attachments = const []}) async* {
    _history.add(ChatMessage(text: prompt, origin: MessageOrigin.user, attachments: const []));
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1));
    
    String response;
    if (prompt.toLowerCase().contains('preview')) {
      final data = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'occupation': 'Architect',
        'details': 'Building a new house.',
      };
      response = 'PREVIEW_DATA:${jsonEncode(data)}\nHere is a preview of the client.';
    } else {
      response = 'AI_SOURCE:cloud\nThis is a mock response from the GenUI SDK.';
    }
    
    _history.add(ChatMessage(text: response, origin: MessageOrigin.llm, attachments: const []));
    notifyListeners();
    yield response;
  }
}

@widgetbook.UseCase(name: 'Default', type: KeyValueChatView)
Widget buildKeyValueChatViewUseCase(BuildContext context) {
  // We need to provide AdvisorProvider and UiContextProvider
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AdvisorProvider()),
      ChangeNotifierProvider(create: (_) => UiContextProvider()),
    ],
    child: Consumer2<AdvisorProvider, UiContextProvider>(
      builder: (context, advisor, ui, child) {
        final mockProvider = MockLlmProvider();
        // Add some initial history
        mockProvider.history = [
          ChatMessage(text: "Hello! I'm your AI assistant. How can I help you today?", origin: MessageOrigin.llm, attachments: const []),
        ];
        
        return Scaffold(
          body: KeyValueChatView(provider: mockProvider),
        );
      },
    ),
  );
}

@widgetbook.UseCase(name: 'With Preview', type: KeyValueChatView)
Widget buildKeyValueChatViewWithPreviewUseCase(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AdvisorProvider()),
      ChangeNotifierProvider(create: (_) => UiContextProvider()),
    ],
    child: Consumer2<AdvisorProvider, UiContextProvider>(
      builder: (context, advisor, ui, child) {
        final mockProvider = MockLlmProvider();
        final data = {
          'name': 'Jane Smith',
          'email': 'jane@example.com',
          'occupation': 'Investor',
          'details': 'Looking for high-growth startups.',
        };
        mockProvider.history = [
          ChatMessage(text: "Can you show me Jane's preview?", origin: MessageOrigin.user, attachments: const []),
          ChatMessage(text: "AI_SOURCE:cloud\nPREVIEW_DATA:${jsonEncode(data)}\nHere is the preview.", origin: MessageOrigin.llm, attachments: const []),
        ];
        
        return Scaffold(
          body: KeyValueChatView(provider: mockProvider),
        );
      },
    ),
  );
}
