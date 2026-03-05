import 'package:firebase_ai/firebase_ai.dart';
import 'dart:convert';
import '../models/customer.dart';

class AiChatMessage {
  final String text;
  final bool isUser;

  AiChatMessage({required this.text, required this.isUser});
}

class AiService {
  final GenerativeModel? _model;
  final String modelName;
  final bool isDemo;
  final Map<String, dynamic>? uiContext;

  AiService({
    GenerativeModel? model, 
    this.modelName = 'gemini-2.5-flash', 
    this.isDemo = false,
    this.uiContext,
  }) : _model = model;

  GenerativeModel get model => _model ?? FirebaseAI.googleAI().generativeModel(
    model: modelName,
    systemInstruction: Content.system('''
Role: Expert "Intelligence Hub" assistant. 
Context: You reside in the "AI Sidebar" and control the "Main Port" via tools.
UI State: ${uiContext != null ? jsonEncode(uiContext) : 'Unknown'}

Mandatory Rules:
1. **Notifications**: Explicitly tell the user what tool you called and what changed (e.g. "I've updated the profile; view it in the Main Port.").
2. **Data Safety**: Before updating profile/guidelines, call `get_current_profile` if the text isn't in your history. 
3. **Proactivity**: Synthesize info into high-quality Markdown. Don't ask for wording; suggest it.
'''),
    tools: [
      Tool.functionDeclarations([
        FunctionDeclaration('update_client_preview', 'Update real-time client onboarding preview.',
          parameters: {
            'name': Schema.string(), 'email': Schema.string(), 'occupation': Schema.string(),
            'details': Schema.string(), 'guidelines': Schema.string(),
          },
        ),
        FunctionDeclaration('create_client', 'Open the "Add Client" registration form. Call this immediately to help the user fill it out.',
          parameters: {
            'name': Schema.string(), 'email': Schema.string(), 'occupation': Schema.string(),
          },
        ),
        FunctionDeclaration('update_profile', 'Update client background profile.',
          parameters: {
            'customerId': Schema.string(),
            'updated_profile': Schema.string(description: 'Full Markdown profile.'),
          },
        ),
        FunctionDeclaration('update_guidelines', 'Update engagement guidelines.',
          parameters: {
            'customerId': Schema.string(),
            'updated_guidelines': Schema.string(description: 'Full Markdown guidelines.'),
          },
        ),
        FunctionDeclaration('update_draft', 'Refine message draft.',
          parameters: {
            'customerId': Schema.string(),
            'refined_draft': Schema.string(),
          },
        ),
        FunctionDeclaration('navigate_to_client', 'Show client detail view.',
          parameters: {'customerId': Schema.string()},
        ),
        FunctionDeclaration('list_clients', 'Show dashboard with optional filter.',
          parameters: {'filter': Schema.string()},
        ),
        FunctionDeclaration('update_client_info', 'Update primary contact info.',
          parameters: {
            'customerId': Schema.string(), 'name': Schema.string(),
            'email': Schema.string(), 'occupation': Schema.string(),
          },
        ),
        FunctionDeclaration('generate_outreach', 'Trigger new proactive draft.',
          parameters: {'customerId': Schema.string()},
        ),
        FunctionDeclaration('get_current_profile', 'Fetch latest client data.',
          parameters: {'customerId': Schema.string()},
        ),
        FunctionDeclaration('manage_schedules', 'Modify engagement schedules.',
          parameters: {
            'customerId': Schema.string(), 'action': Schema.string(description: 'ADD/REMOVE_ALL'),
            'cadenceValue': Schema.number(), 'cadencePeriod': Schema.string(),
          },
        ),
      ])
    ],
  );

  String _formatHistory(List<AiChatMessage> history, {int limit = 8}) {
    final start = history.length > limit ? history.length - limit : 0;
    return history.skip(start).map((m) => "${m.isUser ? 'Advisor' : 'Assistant'}: ${m.text}").join('\n');
  }

  Future<GenerateContentResponse?> getGeneralResponseRaw(List<AiChatMessage> history) async {
    if (isDemo) return null;
    try {
      final prompt = 'Help advisor with clients/navigation.\nHistory:\n${_formatHistory(history)}\nAssistant:';
      return await model.generateContent([Content.text(prompt)]);
    } catch (e) { return null; }
  }

  Future<GenerateContentResponse?> getOnboardingResponseRaw(List<AiChatMessage> history, {bool isExpressiveAiEnabled = true}) async {
    if (isDemo) return null;
    try {
      final prompt = '''
Goal: Onboard client (Name, Email, Occupation). 
Logic: Call `create_client` IMMEDIATELY to open the form, then help the user fill it.
History:
${_formatHistory(history)}
Assistant:''';
      return await model.generateContent([Content.text(prompt)]);
    } catch (e) { return null; }
  }

  Future<String> generateOnboardingResponse(List<AiChatMessage> history, {bool isExpressiveAiEnabled = true}) async {
    if (isDemo) {
      if (history.isEmpty) return "Hello! I'm your AI onboarding assistant. To start, what is the client's full name?";
      if (history.last.text.toLowerCase().contains('john')) return 'PREVIEW_DATA:{"name":"John"} Great. Email and occupation?';
      return "I'm processing...";
    }

    final response = await getOnboardingResponseRaw(history, isExpressiveAiEnabled: isExpressiveAiEnabled);
    if (response == null) return "Connection error.";
    
    final calls = response.functionCalls;
    final text = response.text ?? "";
    if (calls.isNotEmpty) {
      final call = calls.first;
      if (call.name == 'update_client_preview' && isExpressiveAiEnabled) {
        return "PREVIEW_DATA:${jsonEncode(call.args)}\n${text.isNotEmpty ? text : 'Preview updated.'}";
      }
      if (call.name == 'create_client') return text.isNotEmpty ? text : "I've opened the registration form with the details we discussed.";
      return "CONFERENCE_READY";
    }
    return text.isNotEmpty ? text : "Processing...";
  }

  Future<String> generateDraftMessage(Customer customer) async {
    if (isDemo) return "Hi ${customer.name}, just checking in regarding ${customer.occupation}.";
    try {
      final prompt = 'Draft professional check-in for ${customer.name}.\nProfile: ${customer.details}\nRules: ${customer.guidelines}\nReturn message text only.';
      final res = await model.generateContent([Content.text(prompt)]);
      return res.text ?? "Draft failed.";
    } catch (e) { return "Error: $e"; }
  }

  Future<List<String>> extractPointsOfInterest(String response, String guidelines) async {
    if (isDemo) return ["Interest 1", "Interest 2", "Interest 3"];
    try {
      final prompt = 'Extract top 3 points from response based on guidelines.\nGuidelines: $guidelines\nResponse: $response\nReturn bulleted list.';
      final res = await model.generateContent([Content.text(prompt)]);
      return (res.text ?? "").split('\n').where((l) => l.trim().isNotEmpty).toList();
    } catch (e) { return ["Error: $e"]; }
  }

  Future<String> updateCustomerDetails(String currentDetails, String response) async {
    if (isDemo) return "$currentDetails\n- Update: Info added.";
    try {
      final prompt = 'Merge new info into profile. Preserve Markdown.\nProfile: $currentDetails\nResponse: $response\nUpdated Profile:';
      final res = await model.generateContent([Content.text(prompt)]);
      return res.text ?? currentDetails;
    } catch (e) { return currentDetails; }
  }

  Future<GenerateContentResponse?> _getRefinementRaw(String type, String current, String target, List<AiChatMessage> history) async {
    if (isDemo) return null;
    final prompt = 'Refine $type "$target".\nCurrent: $current\nHistory:\n${_formatHistory(history)}\nAssistant:';
    return await model.generateContent([Content.text(prompt)]);
  }

  Future<String> generateProfileRefinementResponse(Customer customer, List<AiChatMessage> history) async {
    if (isDemo) return "Tell me more about ${customer.name}.";
    final res = await _getRefinementRaw('profile', customer.details, customer.name, history);
    return res?.text ?? "Processing...";
  }

  Future<String> extractUpdatedProfile(Customer customer, List<AiChatMessage> history) async {
    final res = await _getRefinementRaw('profile', customer.details, customer.name, history);
    if (res != null && res.functionCalls.isNotEmpty) {
      final call = res.functionCalls.firstWhere((c) => c.name == 'update_profile', orElse: () => res.functionCalls.first);
      return call.args['updated_profile'] as String? ?? customer.details;
    }
    return customer.details;
  }

  Future<String> generateGuidelinesRefinementResponse(Customer customer, List<AiChatMessage> history) async {
    if (isDemo) return "Let's refine guidelines.";
    final res = await _getRefinementRaw('guidelines', customer.guidelines, customer.name, history);
    return res?.text ?? "Processing...";
  }

  Future<String> extractUpdatedGuidelines(Customer customer, List<AiChatMessage> history) async {
    final res = await _getRefinementRaw('guidelines', customer.guidelines, customer.name, history);
    if (res != null && res.functionCalls.isNotEmpty) {
      final call = res.functionCalls.firstWhere((c) => c.name == 'update_guidelines', orElse: () => res.functionCalls.first);
      return call.args['updated_guidelines'] as String? ?? customer.guidelines;
    }
    return customer.guidelines;
  }

  Future<String> generateDraftRefinementResponse(Customer customer, String currentDraft, List<AiChatMessage> history) async {
    if (isDemo) return "How should we adjust the draft?";
    final res = await _getRefinementRaw('draft', currentDraft, customer.name, history);
    return res?.text ?? "Processing...";
  }

  Future<String> finalizeDraftRefinement(Customer customer, String currentDraft, List<AiChatMessage> history) async {
    if (isDemo) return currentDraft;
    final res = await _getRefinementRaw('draft', currentDraft, customer.name, history);
    if (res != null && res.functionCalls.isNotEmpty) {
      return res.functionCalls.first.args['refined_draft'] as String? ?? currentDraft;
    }
    return currentDraft;
  }

  // Support methods for backwards compatibility
  Future<String> finalizeProfileRefinement(Customer customer, List<AiChatMessage> history) => extractUpdatedProfile(customer, history);
  Future<String> finalizeGuidelinesRefinement(Customer customer, List<AiChatMessage> history) => extractUpdatedGuidelines(customer, history);
  Future<Map<String, dynamic>?> extractClientFromFunctionCall(List<AiChatMessage> history, {bool isExpressiveAiEnabled = true}) async {
    final res = await getOnboardingResponseRaw(history, isExpressiveAiEnabled: isExpressiveAiEnabled);
    return res?.functionCalls.isNotEmpty == true ? res!.functionCalls.first.args : null;
  }
}
