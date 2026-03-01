import 'package:firebase_ai/firebase_ai.dart';
import '../models/customer.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class AiService {
  final GenerativeModel? _model;
  final String modelName;
  final bool isDemo;

  AiService({GenerativeModel? model, this.modelName = 'gemini-2.5-flash', this.isDemo = false})
      : _model = model;

  GenerativeModel get _effectiveModel => _model ?? FirebaseAI.googleAI().generativeModel(
    model: modelName,
    tools: [
      Tool.functionDeclarations([
        FunctionDeclaration(
          'create_client',
          'Call this once you have gathered all required client information: Name, Email, Occupation, Details (Background), and Engagement Guidelines.',
          parameters: {
            'name': Schema.string(description: 'Full name of the client'),
            'email': Schema.string(description: 'Email address'),
            'occupation': Schema.string(description: 'Client occupation'),
            'details': Schema.string(description: 'Detailed background/profile (Markdown)'),
            'guidelines': Schema.string(description: 'Engagement rules/guidelines (Markdown)'),
          },
        ),
        FunctionDeclaration(
          'update_profile',
          'Call this once you have gathered enough information to provide a comprehensive, high-quality update to the client profile.',
          parameters: {
            'updated_profile': Schema.string(description: 'The full, updated client profile in Markdown format.'),
          },
        ),
        FunctionDeclaration(
          'update_guidelines',
          'Call this once you have gathered enough information to provide a comprehensive, high-quality update to the engagement guidelines.',
          parameters: {
            'updated_guidelines': Schema.string(description: 'The full, updated engagement guidelines in Markdown format.'),
          },
        )
      ])
    ],
  );

  Future<GenerateContentResponse?> getOnboardingResponseRaw(List<ChatMessage> history) async {
    if (isDemo) return null;

    try {
      final prompt = '''
You are an expert CPA onboarding assistant. Your goal is to help the user create a new client by gathering their Name, Email, Occupation, Detailed Profile (Background), and Engagement Guidelines.

### Process:
1. **Introduction**: Inform the user that you are here to help them create a new client through an interactive conversation.
2. **Data Gathering**: Ask for the missing information one or two pieces at a time. Be professional and friendly.
3. **Clarification**: If the information provided is vague, ask clarification questions to ensure the Profile and Guidelines are high-quality.
4. **Finalization**: Once you have all five pieces of information, call the `create_client` function.

Conversation History:
${history.map((m) => "${m.isUser ? 'User' : 'Assistant'}: ${m.text}").join('\n')}

Assistant:''';

      final content = [Content.text(prompt)];
      return await _effectiveModel.generateContent(content);
    } catch (e) {
      return null;
    }
  }

  Future<String> generateOnboardingResponse(List<ChatMessage> history) async {
    if (isDemo) {
      if (history.isEmpty) return "Hello! I'm your AI onboarding assistant. I'll help you create a new client by gathering their details through a quick conversation. To start, what is the client's full name?";
      if (history.last.text.toLowerCase().contains('john')) return "Great, John Doe. What is his email address and occupation?";
      if (history.any((m) => m.text.contains('@'))) return "I've got those details. Now, could you provide some background details for his profile and any specific engagement guidelines I should follow?";
      return "I'm ready to create the client profile for John Doe once you provide the background and guidelines.";
    }

    final response = await getOnboardingResponseRaw(history);
    if (response == null) return "I'm having trouble connecting to the AI service.";
    
    final text = response.text;
    if (text != null && text.isNotEmpty) return text;
    
    final functionCalls = response.functionCalls;
    if (functionCalls.isNotEmpty) {
      return "CONFERENCE_READY"; // Special token to signal UI to show review
    }
    
    return "I'm processing your request...";
  }

  Future<Map<String, dynamic>?> extractClientFromFunctionCall(List<ChatMessage> history) async {
    if (isDemo) {
      return {
        'name': 'John Doe (Demo)',
        'email': 'john@example.com',
        'occupation': 'Software Engineer',
        'details': 'Extracted via demo conversation.',
        'guidelines': 'Focus on R&D tax credits.',
      };
    }

    final response = await getOnboardingResponseRaw(history);
    if (response != null && response.functionCalls.isNotEmpty) {
      return response.functionCalls.first.args;
    }
    return null;
  }


  Future<String> generateDraftMessage(Customer customer) async {
    if (isDemo) {
      return "Hi ${customer.name}, hope your quarter is going well! I've been reviewing your latest details regarding ${customer.occupation} and wanted to see if we should schedule a quick touchpoint to discuss your tax strategy.";
    }
    try {
      final prompt = '''
Draft a warm, professional check-in message for a CPA to send to their client, ${customer.name}.
Context:
Customer Details (Markdown):
${customer.details}

CPA Engagement Guidelines (Markdown):
${customer.guidelines}

The message should align with the guidelines and reference recent details from the customer's profile.
Return only the message text.
''';
      final content = [Content.text(prompt)];
      final response = await _effectiveModel.generateContent(content);
      return response.text ?? "Failed to generate draft message.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  Future<List<String>> extractPointsOfInterest(String response, String guidelines) async {
    if (isDemo) {
      return [
        "Client mentioned new international sales (Potential tax treaty issues)",
        "Expected revenue increase of 20%",
        "Wants to schedule a follow-up meeting next week"
      ];
    }
    try {
      final prompt = '''
Based on these CPA guidelines, what are the 3 most important points in this customer response?
Guidelines:
$guidelines

Customer Response:
$response

Return a bulleted list of the 3 most important points.
''';
      final content = [Content.text(prompt)];
      final aiResponse = await _effectiveModel.generateContent(content);
      final text = aiResponse.text ?? "";
      return text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    } catch (e) {
      return ["Error extracting points: ${e.toString()}"];
    }
  }

  Future<String> updateCustomerDetails(String currentDetails, String response) async {
    if (isDemo) {
      return "$currentDetails\n\n- **Update (Demo)**: Client reported new growth and international activity in latest response.";
    }
    try {
      final prompt = '''
Update the following markdown customer profile with new information from this customer response.
Preserve the markdown format.
Current Details:
$currentDetails

Customer Response:
$response

Updated Details (Markdown):
''';
      final content = [Content.text(prompt)];
      final aiResponse = await _effectiveModel.generateContent(content);
      return aiResponse.text ?? currentDetails;
    } catch (e) {
      return currentDetails;
    }
  }

  Future<GenerateContentResponse?> getProfileRefinementRaw(Customer customer, List<ChatMessage> history) async {
    if (isDemo) return null;
    try {
      final prompt = '''
You are an expert CPA assistant. You are helping a CPA refine and expand the profile of their client, ${customer.name}.
Current Profile:
${customer.details}

Your goal is to have a professional conversation with the CPA to gather more descriptive details and then summarize them into a high-quality markdown profile.
Once you have enough information to provide a solid update, call the `update_profile` function.
Be concise, inquisitive, and professional.

Conversation History:
${history.map((m) => "${m.isUser ? 'CPA' : 'Assistant'}: ${m.text}").join('\n')}

Assistant:''';
      final content = [Content.text(prompt)];
      return await _effectiveModel.generateContent(content);
    } catch (e) {
      return null;
    }
  }

  Future<String> generateProfileRefinementResponse(Customer customer, List<ChatMessage> history) async {
    if (isDemo) {
      if (history.isEmpty) return "I can help you build a more descriptive profile for ${customer.name}. What recent updates or background information should we add?";
      return "Got it. I'll incorporate that into the profile. Anything else about their financial goals or recent business activities?";
    }

    final response = await getProfileRefinementRaw(customer, history);
    if (response == null) return "I'm having trouble assisting with the profile right now.";
    
    final text = response.text;
    if (text != null && text.isNotEmpty) return text;
    
    if (response.functionCalls.any((call) => call.name == 'update_profile')) {
      return "CONFERENCE_READY";
    }
    
    return "Processing your input...";
  }

  Future<String> extractUpdatedProfile(Customer customer, List<ChatMessage> history) async {
    if (isDemo) return "${customer.details}\n\n### Business & Strategy (Updated via AI)\n- New tech venture launched in Q1.\n- Focus on scaling international operations.\n- Seeking R&D tax credit optimization.";
    
    final response = await getProfileRefinementRaw(customer, history);
    if (response != null && response.functionCalls.isNotEmpty) {
      final call = response.functionCalls.firstWhere((c) => c.name == 'update_profile', orElse: () => response.functionCalls.first);
      final updated = call.args['updated_profile'] as String?;
      return updated ?? customer.details;
    }
    return customer.details;
  }

  Future<String> finalizeProfileRefinement(Customer customer, List<ChatMessage> history) async {
    return await extractUpdatedProfile(customer, history);
  }

  Future<GenerateContentResponse?> getGuidelinesRefinementRaw(Customer customer, List<ChatMessage> history) async {
    if (isDemo) return null;
    try {
      final prompt = '''
You are an expert CPA assistant. You are helping a CPA define "Engagement Guidelines" for their client, ${customer.name}.
Current Guidelines:
${customer.guidelines}

Your goal is to have a professional conversation with the CPA to define how they should proactively engage with this client.
Gather details like: Communication style, proactive focus areas, preferred frequency, and tone.
Once you have enough information to provide a solid set of guidelines, call the `update_guidelines` function.
Be concise, inquisitive, and professional.

Conversation History:
${history.map((m) => "${m.isUser ? 'CPA' : 'Assistant'}: ${m.text}").join('\n')}

Assistant:''';
      final content = [Content.text(prompt)];
      return await _effectiveModel.generateContent(content);
    } catch (e) {
      return null;
    }
  }

  Future<String> generateGuidelinesRefinementResponse(Customer customer, List<ChatMessage> history) async {
    if (isDemo) {
      if (history.isEmpty) return "I can help you craft personalized engagement guidelines for ${customer.name}. What is your primary focus for this client? (e.g., proactive tax planning, monthly check-ins, or R&D focus?)";
      return "Understood. I'll include that. Should we also set specific rules for communication frequency or document request styles?";
    }

    final response = await getGuidelinesRefinementRaw(customer, history);
    if (response == null) return "I'm having trouble assisting with the guidelines right now.";
    
    final text = response.text;
    if (text != null && text.isNotEmpty) return text;
    
    if (response.functionCalls.any((call) => call.name == 'update_guidelines')) {
      return "CONFERENCE_READY";
    }
    
    return "Processing your input...";
  }

  Future<String> extractUpdatedGuidelines(Customer customer, List<ChatMessage> history) async {
    if (isDemo) return "${customer.guidelines}\n\n- **Focus**: Strategic tax planning.\n- **Tone**: Professional and direct.\n- **Frequency**: Monthly touchpoints for R&D review.";
    
    final response = await getGuidelinesRefinementRaw(customer, history);
    if (response != null && response.functionCalls.isNotEmpty) {
      final call = response.functionCalls.firstWhere((c) => c.name == 'update_guidelines', orElse: () => response.functionCalls.first);
      final updated = call.args['updated_guidelines'] as String?;
      return updated ?? customer.guidelines;
    }
    return customer.guidelines;
  }

  Future<String> finalizeGuidelinesRefinement(Customer customer, List<ChatMessage> history) async {
    return await extractUpdatedGuidelines(customer, history);
  }

}
