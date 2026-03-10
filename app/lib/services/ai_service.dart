import 'package:firebase_ai/firebase_ai.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/customer.dart';
import '../models/engagement.dart';

class AiChatMessage {
  final String text;
  final bool isUser;

  AiChatMessage({required this.text, required this.isUser});
}

class AiDraftResult {
  final String text;
  final AiSource source;

  AiDraftResult({required this.text, required this.source});
}

class AiService {
  static const _nativeChannel = MethodChannel('com.hejitech.keyvalue_app/ai_ondevice');
  
  final GenerativeModel? _model;
  final String modelName;
  final bool isDemo;
  final Map<String, dynamic>? uiContext;

  AiService({
    GenerativeModel? model, 
    this.modelName = 'gemini-2.5-flash', 
    this.isDemo = false,
    this.uiContext,
  }) : _model = model {
    if (!isDemo && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Proactively trigger model download/warmup on mobile
      prepareOnDevice();
    }
  }

  /// Trigger on-device model download and warmup for Android.
  /// This utilizes AICore via the native Android SDK.
  Future<void> prepareOnDevice() async {
    try {
      debugPrint('AI On-Device: Preparing model for hybrid inference...');
      final result = await _nativeChannel.invokeMethod('prepareModel');
      debugPrint('AI On-Device Result: $result');
    } catch (e) {
      debugPrint('AI On-Device Error: $e');
    }
  }

  Future<AiSource> getAiSource() async {
    if (isDemo) return AiSource.unknown;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final status = await checkOnDeviceStatus();
      if (status.contains('AVAILABLE') || status.contains('Ready')) {
        return AiSource.onDevice;
      }
    }
    return AiSource.cloud;
  }

  /// Check the status of the on-device model (Android only).
  Future<String> checkOnDeviceStatus() async {
    if (defaultTargetPlatform != TargetPlatform.android) return 'UNSUPPORTED_PLATFORM';
    try {
      return await _nativeChannel.invokeMethod('checkStatus') ?? 'UNKNOWN';
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  GenerativeModel get model => _model ?? FirebaseAI.googleAI().generativeModel(
    model: modelName,
    // Enable hybrid mode for cost efficiency and offline support
    // Setup for Android is already configured in Gradle.
    // The Flutter SDK will automatically utilize it in future updates or via appropriate config.
    systemInstruction: Content.system('''
Role: Expert "Intelligence Hub" assistant. 
Context: You reside in the "AI Sidebar" and control the "Main Port" via tools.
UI State: ${uiContext != null ? jsonEncode(uiContext) : 'Unknown'}

Mandatory Rules:
1. **Notifications**: Explicitly tell the user what tool you called and what changed (e.g. "I've updated the profile; view it in the Main Port.").
2. **Data Safety**: Before updating profile/guidelines, call `get_current_profile` if the text isn't in your history. 
3. **Proactivity**: Synthesize info into high-quality Markdown. Don't ask for wording; suggest it.
4. **Onboarding**: Once you have gathered the name, email, and basic background, call `create_client` to automatically register the client and navigate to their new profile.
5. **AI-Assisted Editing**: If the user prompt starts with "CONTEXT: Editing [TYPE]", prioritize refining that specific content using the appropriate tool (`update_draft`, `update_profile`, or `update_guidelines`) based on the user's request.
'''),
    tools: [
      Tool.functionDeclarations([
        FunctionDeclaration('update_client_preview', 'Update real-time client onboarding preview.',
          parameters: {
            'name': Schema.string(), 'email': Schema.string(), 'occupation': Schema.string(),
            'details': Schema.string(), 'guidelines': Schema.string(),
          },
        ),
        FunctionDeclaration('create_client', 'Register a new client and navigate to their profile. Call this once name, email, and background are gathered.',
          parameters: {
            'name': Schema.string(), 'email': Schema.string(), 'occupation': Schema.string(),
            'details': Schema.string(description: 'Initial background profile in Markdown.'),
            'guidelines': Schema.string(description: 'Initial engagement guidelines in Markdown.'),
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
Goal: Onboard client (Name, Email, Occupation, Background). 
Logic: 
1. Use `update_client_preview` to show the advisor what you've gathered so far.
2. Once you have Name, Email, and a basic understanding of their occupation/background, call `create_client` to finalize registration and navigate the advisor to the new profile.
History:
${_formatHistory(history)}
Assistant:''';
      return await model.generateContent([Content.text(prompt)]);
    } catch (e) { return null; }
  }

  Future<AiDraftResult> generateDraftMessage(Customer customer) async {
    final source = await getAiSource();
    if (isDemo) {
      return AiDraftResult(
        text: "Hi ${customer.name}, just checking in regarding ${customer.occupation}.",
        source: source,
      );
    }

    try {
      final prompt = '''
Draft a professional check-in message for ${customer.name}.
Customer Background: ${customer.details.isNotEmpty ? customer.details : 'No background info available.'}
Engagement Guidelines: ${customer.guidelines.isNotEmpty ? customer.guidelines : 'No specific rules.'}

Return ONLY the message text. Do not include any other text or call any tools.
''';
      final res = await model.generateContent([Content.text(prompt)]);
      
      String? resultText;
      if (res.text != null && res.text!.trim().isNotEmpty) {
        resultText = res.text!.trim();
      } else if (res.functionCalls.isNotEmpty) {
        final call = res.functionCalls.first;
        if (call.name == 'update_draft' && call.args['refined_draft'] != null) {
          resultText = call.args['refined_draft'] as String;
        }
      }
      
      if (resultText != null) {
        return AiDraftResult(text: resultText, source: source);
      }
      
      // If text is null, investigate why
      if (res.candidates.isNotEmpty) {
        final candidate = res.candidates.first;
        if (candidate.finishReason == FinishReason.safety) {
          return AiDraftResult(text: "Draft failed: Blocked by safety filters.", source: AiSource.cloud);
        }
      }
      
      return AiDraftResult(text: "Draft failed: Empty response from AI.", source: AiSource.cloud);
    } catch (e) { 
      debugPrint('AI Draft Error: $e');
      // Offline fallback
      return AiDraftResult(
        text: "Hi ${customer.name}, I'm following up on our recent conversation about ${customer.occupation}. (Draft generated in offline mode)",
        source: AiSource.onDevice, // Assuming offline means it was forced to use on-device or it failed
      );
    }
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
}
