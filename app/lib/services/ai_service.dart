import 'package:firebase_ai/firebase_ai.dart';
import '../models/customer.dart';

class AiService {
  final GenerativeModel? _model;
  final bool isDemo;

  AiService({GenerativeModel? model, this.isDemo = false})
      : _model = model;

  GenerativeModel get _effectiveModel => _model ?? FirebaseAI.googleAI().generativeModel(model: 'gemini-1.5-flash');

  Future<String> generateDraftMessage(Customer customer) async {
    if (isDemo) {
      return "Hi ${customer.name}, I've been reviewing your latest details. It looks like you've had some significant growth recently! I'd love to check in and see how we can optimize your tax strategy for the upcoming quarter.";
    }
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
  }

  Future<List<String>> extractPointsOfInterest(String response, String guidelines) async {
    if (isDemo) {
      return [
        "Client mentioned new international sales (Potential tax treaty issues)",
        "Expected revenue increase of 20%",
        "Wants to schedule a follow-up meeting next week"
      ];
    }
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
  }

  Future<String> updateCustomerDetails(String currentDetails, String response) async {
    if (isDemo) {
      return "$currentDetails\n\n- **Update (Demo)**: Client reported new growth and international activity in latest response.";
    }
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
  }
}
