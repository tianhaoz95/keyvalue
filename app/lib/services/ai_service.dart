import 'package:firebase_ai/firebase_ai.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import 'web_ai_utils.dart' as web_utils;

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

class AiProfileUpdate {
  final String updatedContent;
  final String summary;

  AiProfileUpdate({required this.updatedContent, required this.summary});
}

class AiService {
  static const _nativeChannel = MethodChannel('com.hejitech.keyvalue_app/ai_ondevice');
  
  final GenerativeModel? _model;
  final String modelName;
  final bool isDemo;
  final Map<String, dynamic>? uiContext;
  final bool preferOnDeviceAi;

  AiService({
    GenerativeModel? model, 
    this.modelName = 'gemini-2.5-flash', 
    this.isDemo = false,
    this.uiContext,
    this.preferOnDeviceAi = false,
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
    
    if (kIsWeb) {
      // Check for Web On-Device AI (Chrome Prompt API)
      final available = await web_utils.isWebAiAvailable();
      final online = web_utils.isWebOnline();
      
      if (!online && available) return AiSource.onDevice;
      if (preferOnDeviceAi && available) return AiSource.onDevice;
      return AiSource.cloud; 
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // For Android, we could also check connectivity here if needed
      // But we'll rely on the status check for now.
      final status = await checkOnDeviceStatus();
      if (status.contains('AVAILABLE') || status.contains('Ready')) {
        // Only return onDevice if we are likely offline or specifically want it.
        // For now, let's keep it as is, but GlobalChatProvider will handle the fallback.
        // Actually, to fix the user's issue, if they are offline, we should return onDevice.
        if (preferOnDeviceAi) return AiSource.onDevice;
        return AiSource.cloud; // Default to cloud, GlobalChatProvider will fallback.
      }
    }
    return AiSource.cloud;
  }

  /// Generate a response using on-device models as a fallback.
  Future<String> generateOnDeviceResponse(String prompt) async {
    if (kIsWeb) {
      return await web_utils.promptWebAi(prompt);
    }
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final result = await _nativeChannel.invokeMethod('generateContent', {'prompt': prompt});
        return result as String? ?? "Offline response failed.";
      } catch (e) {
        return "Offline: Unable to process request locally. ($e)";
      }
    }
    
    return "Offline: AI is currently unavailable.";
  }

  /// Check the status of the on-device model.
  Future<String> checkOnDeviceStatus() async {
    if (kIsWeb) {
      return await web_utils.getWebAiStatus();
    }
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
6. **Change Summaries**: When calling `update_profile` or `update_guidelines`, you MUST provide a concise one-sentence summary of what specifically was changed in the "summary" argument.
'''),
    tools: [
      Tool.functionDeclarations([
        FunctionDeclaration('update_client_preview', 'Update real-time client onboarding preview.',
          parameters: {
            'name': Schema.string(), 'email': Schema.string(), 'occupation': Schema.string(),
            'details': Schema.string(), 'guidelines': Schema.string(),
            'preferredChannel': Schema.string(description: 'Preferred channel: "email" or "sms".'),
          },
        ),
        FunctionDeclaration('create_client', 'Register a new client and navigate to their profile. Call this once name, email, and background are gathered.',
          parameters: {
            'name': Schema.string(), 'email': Schema.string(), 'occupation': Schema.string(),
            'details': Schema.string(description: 'Initial background profile in Markdown.'),
            'guidelines': Schema.string(description: 'Initial engagement guidelines in Markdown.'),
            'preferredChannel': Schema.string(description: 'Preferred channel: "email" or "sms".'),
          },
        ),
        FunctionDeclaration('update_profile', 'Update client background profile.',
          parameters: {
            'customerId': Schema.string(),
            'updated_profile': Schema.string(description: 'Full Markdown profile.'),
            'summary': Schema.string(description: 'One sentence summary of what changed.'),
          },
        ),
        FunctionDeclaration('update_guidelines', 'Update engagement guidelines.',
          parameters: {
            'customerId': Schema.string(),
            'updated_guidelines': Schema.string(description: 'Full Markdown guidelines.'),
            'summary': Schema.string(description: 'One sentence summary of what changed.'),
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
            'preferredChannel': Schema.string(description: 'Preferred channel: "email" or "sms".'),
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
      // Offline fallback to on-device AI
      final offlineDraft = await generateOnDeviceResponse(
        "Draft a professional check-in message for ${customer.name} regarding ${customer.occupation}."
      );
      
      return AiDraftResult(
        text: offlineDraft.contains('Offline:') 
            ? "Hi ${customer.name}, I'm following up on our recent conversation about ${customer.occupation}. (Standard offline draft)"
            : offlineDraft,
        source: AiSource.onDevice,
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

  Future<AiProfileUpdate> updateCustomerDetails(String currentDetails, String response) async {
    if (isDemo) {
      return AiProfileUpdate(
        updatedContent: "$currentDetails\n- Update: Info added.",
        summary: "Added a new update based on customer response.",
      );
    }
    try {
      final prompt = '''
Merge new info from the response into the current profile. Preserve Markdown.
Profile: $currentDetails
Response: $response

Return the result as a JSON object with exactly two fields:
1. "updated_profile": The full updated Markdown profile.
2. "summary": A very brief (1 sentence) summary of what specifically changed or was added.

JSON:''';
      final res = await model.generateContent([Content.text(prompt)]);
      final text = res.text ?? "";
      
      // Try to parse JSON
      try {
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonStr = text.substring(jsonStart, jsonEnd + 1);
          final data = jsonDecode(jsonStr);
          return AiProfileUpdate(
            updatedContent: data['updated_profile'] as String? ?? currentDetails,
            summary: data['summary'] as String? ?? "Profile updated.",
          );
        }
      } catch (e) {
        debugPrint('Failed to parse AI profile update JSON: $e');
      }
      
      return AiProfileUpdate(updatedContent: text.isNotEmpty ? text : currentDetails, summary: "Profile updated.");
    } catch (e) { 
      return AiProfileUpdate(updatedContent: currentDetails, summary: "Update failed."); 
    }
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
