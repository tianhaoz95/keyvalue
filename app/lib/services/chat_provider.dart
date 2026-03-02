import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'ai_service.dart' as ai;
import '../models/customer.dart';
import '../providers/cpa_provider.dart';

enum ChatContext { onboarding, profile, guidelines }

class KeyValueChatProvider extends ChangeNotifier implements LlmProvider {
  final ai.AiService _aiService;
  final ChatContext _context;
  final Customer? _customer;
  // ignore: unused_field
  final CpaProvider _cpaProvider;
  final Function(String)? onConferenceReady;

  List<ChatMessage> _history = [];

  KeyValueChatProvider({
    required ai.AiService aiService,
    required ChatContext context,
    required CpaProvider cpaProvider,
    Customer? customer,
    this.onConferenceReady,
  })  : _aiService = aiService,
        _context = context,
        _cpaProvider = cpaProvider,
        _customer = customer;

  @override
  Iterable<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> history) {
    _history = history.toList();
    notifyListeners();
  }

  @override
  Stream<String> generateStream(String prompt, {Iterable<Attachment> attachments = const []}) {
    // This is for one-off generations, which we don't use much in the chat UI.
    return Stream.empty();
  }

  @override
  Stream<String> sendMessageStream(String prompt, {Iterable<Attachment> attachments = const []}) async* {
    // 1. Add user message to history
    final userMsg = ChatMessage(
      text: prompt,
      origin: MessageOrigin.user,
      attachments: attachments.toList(),
    );
    _history.add(userMsg);
    notifyListeners();

    // 2. Prepare history for AI service
    final aiHistory = _history.map((m) => ai.AiChatMessage(
      text: m.text ?? "",
      isUser: m.origin == MessageOrigin.user,
    )).toList();

    // 3. Get AI response
    String response;
    try {
      switch (_context) {
        case ChatContext.onboarding:
          response = await _aiService.generateOnboardingResponse(aiHistory);
          break;
        case ChatContext.profile:
          response = await _aiService.generateProfileRefinementResponse(_customer!, aiHistory);
          break;
        case ChatContext.guidelines:
          response = await _aiService.generateGuidelinesRefinementResponse(_customer!, aiHistory);
          break;
      }
    } catch (e) {
      response = "Error: $e";
    }

    // 4. Handle response
    if (response == 'CONFERENCE_READY') {
      if (onConferenceReady != null) {
        onConferenceReady!(response);
      }
      // We don't yield anything here so the user doesn't see "CONFERENCE_READY"
      yield "";
    } else {
      final llmMsg = ChatMessage(
        text: response,
        origin: MessageOrigin.llm,
        attachments: const [],
      );
      _history.add(llmMsg);
      notifyListeners();
      yield response;
    }
  }
}
