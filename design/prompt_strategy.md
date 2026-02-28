# AI Prompt Strategy for CPA Proactive Engagement

## 1. Research Process
The goal was to enhance the current AI-generated check-in messages by incorporating historical context (previous greetings and customer responses), alongside existing customer profiles and CPA guidelines.

### Findings
- **Data Availability**: The `Customer` model contains `details` (profile) and `guidelines`. The `Engagement` model contains `sentMessage` and `customerResponse`, providing a clear audit trail.
- **Current State**: The `AiService` currently generates drafts using only `details` and `guidelines`, ignoring past interactions. This can lead to repetitive or redundant greetings.
- **Requirement**: A unified prompt template that structures these three distinct data sources into a coherent context for the LLM (Gemini 1.5 Flash).

---

## 2. Final Prompt Template
This template is designed to be populated dynamically by the application.

```markdown
### System Role
You are an expert CPA Assistant. Your task is to draft a personalized, warm, and professional check-in message from a CPA to their client.

### Context
#### 1. Customer Profile (Markdown)
${customerProfile}

#### 2. CPA Engagement Guidelines (Markdown)
${cpaGuidelines}

#### 3. Recent Interaction History
| Date | CPA Greeting | Customer Response |
| :--- | :--- | :--- |
${interactionHistoryTable}

### Instructions
- **Acknowledge History**: Briefly reference or build upon the last interaction if relevant (e.g., "Following up on our discussion about...") but avoid being repetitive.
- **Align with Guidelines**: Ensure the tone and topics match the CPA's specific rules.
- **Personalize**: Use details from the Customer Profile to make the message feel bespoke.
- **Call to Action**: Include a low-pressure invitation to share updates or schedule a brief sync if appropriate.
- **Output**: Return ONLY the message text. No preamble or markdown styling for the message itself.
```

---

## 3. Implementation Options

### Option A: Direct Service Update (Recommended)
Modify `AiService.generateDraftMessage` to accept a `List<Engagement>`.
- **Pros**: Simplest integration; leverages existing service pattern.
- **Cons**: Requires minor refactoring of the calling site (Dashboard or Repository).

### Option B: Context Aggregator Pattern
Create a `PromptContext` class that handles the markdown formatting of the profile, guidelines, and history table before passing it to the `AiService`.
- **Pros**: Keeps `AiService` clean and focused on API interaction; easier to unit test prompt construction.
- **Cons**: Adds another layer of abstraction.

### Option C: History-Aware Repository
Update `CustomerRepository` or `EngagementRepository` to include a method `generateHistoricalContext(String customerId)` that returns the formatted history string.
- **Pros**: Centralizes data fetching and formatting.
- **Cons**: Mixes data retrieval with content generation logic.

---

## 4. Proposed Code Snippets

### History Formatting (Dart)
```dart
String formatHistory(List<Engagement> engagements) {
  if (engagements.isEmpty) return "No previous history.";
  final buffer = StringBuffer();
  for (var e in engagements.take(3)) { // Only last 3 for context efficiency
    final date = DateFormat('yyyy-MM-dd').format(e.createdAt);
    buffer.writeln("| $date | ${e.sentMessage} | ${e.customerResponse} |");
  }
  return buffer.toString();
}
```

### Prompt Integration
```dart
final prompt = '''
[System Role and Context Headers as defined above]
...
${formatHistory(history)}
...
''';
```
