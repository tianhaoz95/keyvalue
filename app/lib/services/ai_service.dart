import 'package:firebase_ai/firebase_ai.dart';
import '../models/customer.dart';
import 'dart:convert';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class AiService {
  final GenerativeModel? _model;
  final bool isDemo;

  AiService({GenerativeModel? model, this.isDemo = false})
      : _model = model;

  GenerativeModel get _effectiveModel => _model ?? FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash-lite');

  Future<String> generateOnboardingResponse(List<ChatMessage> history) async {
    if (isDemo) {
      if (history.length <= 1) return "Hello! I'm your AI onboarding assistant. To get started, what is the new client's full name?";
      if (history.last.text.toLowerCase().contains('john')) return "Great, John Doe. What is his email address and occupation?";
      return "I've got those details. Any specific engagement guidelines I should keep in mind for him?";
    }

    try {
      final prompt = '''
You are an expert CPA assistant helping to onboard a new client.
Your goal is to gather: Name, Email, Occupation, and Engagement Guidelines.
Be professional, concise, and friendly.

Conversation History:
${history.map((m) => "${m.isUser ? 'User' : 'Assistant'}: ${m.text}").join('\n')}

Assistant:''';

      final content = [Content.text(prompt)];
      final response = await _effectiveModel.generateContent(content);
      return response.text ?? "I'm sorry, I'm having trouble responding right now.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  Future<Customer?> processOnboardingConversation(List<ChatMessage> history) async {
    if (isDemo) {
      return Customer(
        customerId: 'temp_id',
        name: 'John Doe (Demo)',
        email: 'john@example.com',
        occupation: 'Software Engineer',
        details: 'Extracted via AI conversation.',
        guidelines: 'Focus on R&D tax credits.',
        engagementFrequencyDays: 30,
        nextEngagementDate: DateTime.now(),
        lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
      );
    }

    try {
      final prompt = '''
Based on the following conversation, extract the details for a new CPA client.
Return a JSON object with these keys: name, email, occupation, details, guidelines.
If a field is missing, use an empty string.

Conversation:
${history.map((m) => "${m.isUser ? 'User' : 'Assistant'}: ${m.text}").join('\n')}

JSON Output:''';

      final content = [Content.text(prompt)];
      final response = await _effectiveModel.generateContent(content);
      final text = response.text ?? "{}";
      
      // Clean up markdown if AI returns it
      final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final data = jsonDecode(cleanJson);
      return Customer(
        customerId: DateTime.now().millisecondsSinceEpoch.toString(),
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        occupation: data['occupation'] ?? '',
        details: data['details'] ?? 'Extracted via AI onboarding.',
        guidelines: data['guidelines'] ?? '',
        engagementFrequencyDays: 30,
        nextEngagementDate: DateTime.now(),
        lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
      );
    } catch (e) {
      return null;
    }
  }

  Future<String> generateDraftMessage(Customer customer) async {
    if (isDemo) {
      return "Hi ${customer.name}, I've been reviewing your latest details. It looks like you've had some significant growth recently! I'd love to check in and see how we can optimize your tax strategy for the upcoming quarter.";
    }
    try {
      final prompt = '''
Draft a warm, professional check-in message for a CPA to send to their client.
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

  Future<String> generateProfileRefinementResponse(Customer customer, List<ChatMessage> history) async {
    if (isDemo) {
      if (history.isEmpty) return "I can help you build a more descriptive profile for ${customer.name}. What recent updates or background information should we add?";
      return "Got it. I'll incorporate that into the profile. Anything else about their financial goals or recent business activities?";
    }

    try {
      final prompt = '''
You are an expert CPA assistant. You are helping a CPA refine and expand the profile of their client, ${customer.name}.
Current Profile:
${customer.details}

Your goal is to have a professional conversation with the CPA to gather more descriptive details and then summarize them into a high-quality markdown profile.
Be concise, inquisitive, and professional.

Conversation History:
${history.map((m) => "${m.isUser ? 'CPA' : 'Assistant'}: ${m.text}").join('\n')}

Assistant:''';

      final content = [Content.text(prompt)];
      final response = await _effectiveModel.generateContent(content);
      return response.text ?? "I'm having trouble assisting with the profile right now.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  Future<String> finalizeProfileRefinement(Customer customer, List<ChatMessage> history) async {
    if (isDemo) {
      return "${customer.details}\n\n### Business & Strategy (Updated via AI)\n- New tech venture launched in Q1.\n- Focus on scaling international operations.\n- Seeking R&D tax credit optimization.";
    }

    try {
      final prompt = '''
Based on the following conversation between a CPA and an AI assistant, update the client profile for ${customer.name}.
The output must be a clean, professional markdown document that merges the current profile with the new insights.

Current Profile:
${customer.details}

Conversation:
${history.map((m) => "${m.isUser ? 'CPA' : 'Assistant'}: ${m.text}").join('\n')}

Updated Markdown Profile:''';

      final content = [Content.text(prompt)];
      final response = await _effectiveModel.generateContent(content);
      return response.text ?? customer.details;
    } catch (e) {
      return customer.details;
    }
  }

  Future<String> generateGuidelinesRefinementResponse(Customer customer, List<ChatMessage> history) async {
    if (isDemo) {
      if (history.isEmpty) return "I can help you craft personalized engagement guidelines for ${customer.name}. What is your primary focus for this client? (e.g., proactive tax planning, monthly check-ins, or R&D focus?)";
      return "Understood. I'll include that. Should we also set specific rules for communication frequency or document request styles?";
    }

    try {
      final prompt = '''
You are an expert CPA assistant. You are helping a CPA define "Engagement Guidelines" for their client, ${customer.name}.
Current Guidelines:
${customer.guidelines}

Your goal is to have a professional conversation with the CPA to define how they should proactively engage with this client.
Gather details like: Communication style, proactive focus areas, preferred frequency, and tone.
Then, you will summarize these into a high-quality markdown guideline.
Be concise, inquisitive, and professional.

Conversation History:
${history.map((m) => "${m.isUser ? 'CPA' : 'Assistant'}: ${m.text}").join('\n')}

Assistant:''';

      final content = [Content.text(prompt)];
      final response = await _effectiveModel.generateContent(content);
      return response.text ?? "I'm having trouble assisting with the guidelines right now.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  Future<String> finalizeGuidelinesRefinement(Customer customer, List<ChatMessage> history) async {
    if (isDemo) {
      return "${customer.guidelines}\n\n- **Focus**: Strategic tax planning.\n- **Tone**: Professional and direct.\n- **Frequency**: Monthly touchpoints for R&D review.";
    }

    try {
      final prompt = '''
Based on the following conversation between a CPA and an AI assistant, update the Engagement Guidelines for ${customer.name}.
The output must be a clean, professional markdown list of guidelines that the AI will use to draft future messages.

Current Guidelines:
${customer.guidelines}

Conversation:
${history.map((m) => "${m.isUser ? 'CPA' : 'Assistant'}: ${m.text}").join('\n')}

Updated Markdown Guidelines:''';

      final content = [Content.text(prompt)];
      final response = await _effectiveModel.generateContent(content);
      return response.text ?? customer.guidelines;
    } catch (e) {
      return customer.guidelines;
    }
  }
}
