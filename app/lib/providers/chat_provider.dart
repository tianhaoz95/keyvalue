import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../services/ai_service.dart' as ai;
import '../models/customer.dart';
import '../providers/advisor_provider.dart';
import '../providers/ui_context_provider.dart';

class GlobalChatProvider extends ChangeNotifier implements LlmProvider {
  final AdvisorProvider _advisorProvider;
  final UiContextProvider _uiContext;

  List<ChatMessage> _history = [];
  bool _isLoading = false;

  GlobalChatProvider({
    required AdvisorProvider advisorProvider,
    required UiContextProvider uiContext,
  })  : _advisorProvider = advisorProvider,
        _uiContext = uiContext;

  @override
  Iterable<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> history) {
    _history = history.toList();
    notifyListeners();
  }

  bool get isLoading => _isLoading;

  void clearHistory() {
    _history = [];
    _uiContext.clearDraftContext();
    notifyListeners();
  }

  @override
  Stream<String> generateStream(String prompt, {Iterable<Attachment> attachments = const []}) {
    return Stream.empty();
  }

  @override
  Stream<String> sendMessageStream(String prompt, {Iterable<Attachment> attachments = const []}) async* {
    final aiService = _advisorProvider.aiService;
    
    // 1. Prepare effective prompt with context if available
    String effectivePrompt = prompt;
    if (_uiContext.activeEditContext != null) {
      final contextType = _uiContext.activeEditContext!.type.toString().split('.').last.toUpperCase();
      effectivePrompt = "CONTEXT: Editing $contextType: \"${_uiContext.activeEditContext!.content}\"\n\nUSER REQUEST: $prompt";
    }

    // 2. Add user message to history (original prompt for UI, but maybe effective for AI)
    final userMsg = ChatMessage(
      text: prompt,
      origin: MessageOrigin.user,
      attachments: attachments.toList(),
    );
    _history.add(userMsg);
    notifyListeners();

    // 3. Prepare history for AI service
    final List<ai.AiChatMessage> aiHistory = _history.map((m) {
      String text = m.text ?? "";
      if (text.startsWith('PREVIEW_DATA:')) {
        final parts = text.split('\n');
        text = parts.length > 1 ? parts.sublist(1).join('\n') : "";
      }
      return ai.AiChatMessage(
        text: text,
        isUser: m.origin == MessageOrigin.user,
      );
    }).where((m) => m.text.isNotEmpty).toList();

    // 4. Get AI response based on current UI context
    String response = "";
    try {
      _isLoading = true;
      notifyListeners();

      // Convert aiHistory (excluding the current prompt) to Content list for startChat
      final List<Content> chatHistory = aiHistory.length > 1 
          ? aiHistory.sublist(0, aiHistory.length - 1).map((m) {
              return Content(m.isUser ? 'user' : 'model', [TextPart(m.text)]);
            }).toList()
          : [];

      final chat = aiService.model.startChat(history: chatHistory);
      var aiResponse = await chat.sendMessage(Content.text(effectivePrompt));

      // Execution Loop for Tool Calling
      int loopCount = 0;
      final List<String> toolsCalled = [];
      while (aiResponse.functionCalls.isNotEmpty && loopCount < 5) {
        loopCount++;
        final toolResponses = <FunctionResponse>[];
        
        for (final call in aiResponse.functionCalls) {
          toolsCalled.add(call.name);
          final result = await _executeAiTool(call);
          
          // Clear draft context if update_draft was called successfully
          if (call.name == 'update_draft' && result == null) {
            _uiContext.clearEditContext();
          }
          
          // Clear edit context if profile or guidelines were updated
          if ((call.name == 'update_profile' || call.name == 'update_guidelines') && result == null) {
            _uiContext.clearEditContext();
          }

          if (result != null) {
            toolResponses.add(result);
            if (call.name == 'update_client_preview') {
              response = 'PREVIEW_DATA:${jsonEncode(call.args)}\nI\'ve updated the preview for you.';
            } else if (call.name == 'update_profile' && _uiContext.isMobile) {
              response = 'PREVIEW_DATA:${jsonEncode(result.response)}\nI\'ve updated the client profile for you.';
            }
          } else {
            // For actions that don't return data, we should still provide a success response
            // so the AI can continue if it needs to.
            toolResponses.add(FunctionResponse(call.name, {'status': 'success'}));
          }
        }
        
        aiResponse = await chat.sendMessage(Content.functionResponses(toolResponses));
      }

      if (response.isEmpty) {
        response = aiResponse.text ?? (toolsCalled.isNotEmpty 
          ? "I've handled those tasks for you: ${toolsCalled.toSet().join(', ')}." 
          : "I'm not sure how to respond.");
      }
    } catch (e) {
      response = "Error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // 5. Handle response tokens
    if (response == 'CONFERENCE_READY') {
      final llmMsg = ChatMessage(
        text: "I've gathered all the information. Ready to proceed!",
        origin: MessageOrigin.llm,
        attachments: const [],
      );
      _history.add(llmMsg);
      notifyListeners();
      yield "Ready to proceed!";
    } else if (response.startsWith('PREVIEW_DATA:')) {
      final llmMsg = ChatMessage(
        text: response,
        origin: MessageOrigin.llm,
        attachments: const [],
      );
      _history.add(llmMsg);
      notifyListeners();

      final lines = response.split('\n');
      if (lines.length > 1) {
        yield lines.sublist(1).join('\n');
      } else {
        yield "I've updated the record preview.";
      }
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

  Future<FunctionResponse?> _executeAiTool(FunctionCall call) async {
    switch (call.name) {
      case 'update_client_preview':
        // This is handled by responseBuilder in KeyValueChatView via PREVIEW_DATA:
        // but we still need to return a success status to the model.
        return FunctionResponse(call.name, {'status': 'success'});
      case 'get_current_profile':
        final customerId = call.args['customerId'] as String? ?? _uiContext.activeCustomerId;
        if (customerId != null) {
          try {
            final customer = _advisorProvider.customers.firstWhere((c) => c.customerId == customerId);
            return FunctionResponse(call.name, {
              'details': customer.details,
              'guidelines': customer.guidelines,
              'name': customer.name,
              'occupation': customer.occupation,
            });
          } catch (e) {
            return FunctionResponse(call.name, {'error': 'Customer not found'});
          }
        }
        return FunctionResponse(call.name, {'error': 'No customer ID provided'});
      case 'navigate_to_client':
        final customerId = call.args['customerId'] as String?;
        if (customerId != null) {
          _uiContext.setView(AppView.customerDetail, customerId: customerId);
        }
        break;
      case 'list_clients':
        _uiContext.setView(AppView.dashboard);
        break;
      case 'create_client':
        final name = call.args['name'] as String?;
        final email = call.args['email'] as String?;
        final occupation = call.args['occupation'] as String?;
        final details = call.args['details'] as String?;
        final guidelines = call.args['guidelines'] as String?;
        
        if (name != null && email != null) {
          final customerId = DateTime.now().millisecondsSinceEpoch.toString();
          final newCustomer = Customer(
            customerId: customerId,
            name: name,
            email: email,
            occupation: occupation ?? '',
            details: details ?? '',
            guidelines: guidelines ?? '',
            engagementFrequencyDays: 30,
            nextEngagementDate: DateTime.now(),
            lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
          );
          
          await _advisorProvider.addCustomer(newCustomer);
          _uiContext.setView(AppView.customerDetail, customerId: customerId);
          return FunctionResponse(call.name, {'status': 'success', 'customerId': customerId});
        }
        return FunctionResponse(call.name, {'error': 'Missing required fields (name, email)'});
      case 'update_client_info':
        final customerId = call.args['customerId'] as String?;
        final name = call.args['name'] as String?;
        final email = call.args['email'] as String?;
        final occupation = call.args['occupation'] as String?;
        if (customerId != null) {
          final customer = _advisorProvider.customers.firstWhere((c) => c.customerId == customerId);
          final updated = customer.copyWith(
            name: name ?? customer.name,
            email: email ?? customer.email,
            occupation: occupation ?? customer.occupation,
          );
          await _advisorProvider.addCustomer(updated);
          _uiContext.setView(AppView.customerDetail, customerId: customerId);
        }
        break;
      case 'generate_outreach':
        final customerId = call.args['customerId'] as String?;
        if (customerId != null) {
          final customer = _advisorProvider.customers.firstWhere((c) => c.customerId == customerId);
          await _advisorProvider.generateManualDraft(customer);
          _uiContext.setView(AppView.customerDetail, customerId: customerId);
        }
        break;
      case 'manage_schedules':
        final customerId = call.args['customerId'] as String?;
        final action = call.args['action'] as String?;
        if (customerId != null && action != null) {
          final customer = _advisorProvider.customers.firstWhere((c) => c.customerId == customerId);
          if (action == 'ADD') {
            final value = call.args['cadenceValue'] as double?;
            final period = call.args['cadencePeriod'] as String?;
            if (value != null && period != null) {
              final schedule = EngagementSchedule(
                scheduleId: const Uuid().v4(),
                startDate: DateTime.now(),
                cadenceValue: value.toInt(),
                cadencePeriod: period,
              );
              final updated = customer.copyWith(schedules: [...customer.schedules, schedule]);
              await _advisorProvider.addCustomer(updated);
            }
          } else if (action == 'REMOVE_ALL') {
            final updated = customer.copyWith(schedules: []);
            await _advisorProvider.addCustomer(updated);
          }
          _uiContext.setView(AppView.customerDetail, customerId: customerId);
        }
        break;
      case 'update_profile':
        final customerId = call.args['customerId'] as String? ?? _uiContext.activeCustomerId;
        final updatedProfile = call.args['updated_profile'] as String?;
        if (updatedProfile != null && customerId != null) {
           final customer = _advisorProvider.customers.firstWhere((c) => c.customerId == customerId);
           final updated = customer.copyWith(proposedDetails: updatedProfile);
           await _advisorProvider.addCustomer(updated);
           _uiContext.setView(AppView.customerDetail, customerId: customerId);
           
           if (_uiContext.isMobile) {
             return FunctionResponse(call.name, {
               'status': 'success',
               'name': customer.name,
               'email': customer.email,
               'occupation': customer.occupation,
               'details': updatedProfile,
               'guidelines': customer.guidelines,
             });
           }
        }
        break;
      case 'update_guidelines':
        final customerId = call.args['customerId'] as String? ?? _uiContext.activeCustomerId;
        final updatedGuidelines = call.args['updated_guidelines'] as String?;
        if (updatedGuidelines != null && customerId != null) {
           final customer = _advisorProvider.customers.firstWhere((c) => c.customerId == customerId);
           final updated = customer.copyWith(proposedGuidelines: updatedGuidelines);
           await _advisorProvider.addCustomer(updated);
           _uiContext.setView(AppView.customerDetail, customerId: customerId);
        }
        break;
      case 'update_draft':
        final customerId = call.args['customerId'] as String? ?? _uiContext.activeCustomerId;
        final refinedDraft = call.args['refined_draft'] as String?;
        if (refinedDraft != null && customerId != null) {
          await _advisorProvider.updateDraft(
            customerId, 
            refinedDraft, 
            engagementId: _uiContext.activeDraftEngagementId,
          );
          _uiContext.setView(AppView.customerDetail, customerId: customerId);
        }
        break;
    }
    return null;
  }
}
