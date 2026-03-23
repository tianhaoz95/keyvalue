# AI Prompt Strategy for CPA Proactive Engagement (KeyValue)

This document outlines the core strategy and specific prompt templates used to drive the "App-as-Engine" experience in the KeyValue application using Google Gemini.

## 1. Core Principles
- **Professional & Bespoke**: Every AI-generated message must feel like it was personally crafted by a senior CPA.
- **Human-in-the-Loop**: AI suggestions (drafts, profile updates) are always presented for review and require CPA approval before being finalized.
- **Markdown-First**: All client profiles and engagement rules are stored and processed as Markdown to preserve structure and readability.
- **Deterministic-ish**: Use system roles and clear output constraints (e.g., "Return ONLY the message text") to ensure consistency across the UI.

---

## 2. Proactive Draft Generation
The goal is to generate personalized check-in messages that reference client details and adhere to CPA-defined rules.

### Current Implementation
Used in `AiService.generateDraftMessage`. It leverages the client's current profile and rules.

```markdown
Draft a warm, professional check-in message for a CPA to send to their client, ${customerName}.

### Context
#### 1. Customer Profile (Markdown)
${customerDetails}

#### 2. CPA Engagement Guidelines (Markdown)
${cpaGuidelines}

### Instructions
- Align with the guidelines.
- Reference recent details from the customer's profile.
- Return ONLY the message text. No preamble or markdown styling.
```

### Future Enhancement: History-Aware Drafts
To prevent repetitive greetings, the strategy includes incorporating recent interaction history into the context.

```markdown
### Context
#### 3. Recent Interaction History
| Date | CPA Greeting | Customer Response |
| :--- | :--- | :--- |
${interactionHistoryTable}

### Instructions
- **Acknowledge History**: Briefly reference or build upon the last interaction if relevant, but avoid being repetitive.
```

---

## 3. Intelligence Hub (Response Processing)
When a client responds, the AI performs a two-step analysis to provide actionable insights and update records.

### A. Points of Interest Extraction
Identifies the top 3 most important items for the CPA to notice.

```markdown
Based on these CPA guidelines, what are the 3 most important points in this customer response?

### Guidelines
${guidelines}

### Customer Response
${response}

### Output
Return a bulleted list of the 3 most important points.
```

### B. Profile Update (Diff Generation)
Generates a new version of the client profile incorporating new information.

```markdown
Update the following markdown customer profile with new information from this customer response.
Preserve the markdown format.

### Current Details
${currentDetails}

### Customer Response
${response}

### Updated Details (Markdown)
[Full updated profile text]
```

---

## 4. Seamless Onboarding
Uses a conversational flow to gather client data and then extracts it into a structured format.

### A. Onboarding Conversation
```markdown
You are an expert CPA assistant helping to onboard a new client.
Your goal is to gather: Name, Email, Occupation, and Engagement Guidelines.
Be professional, concise, and friendly.

Conversation History:
${history}
```

### B. Structured Data Extraction
```markdown
Based on the following conversation, extract the details for a new CPA client.
Return a JSON object with these keys: name, email, occupation, details, guidelines.
If a field is missing, use an empty string.

Conversation:
${history}

JSON Output:
```

---

## 5. Interactive Refinement (Profile & Rules)
Allows the CPA to "chat" with the AI to build out more complex profiles or rulesets.

- **Conversation Mode**: Assistant acts as an interviewer, asking clarifying questions about the client's financial goals or the CPA's preferred tone.
- **Finalization Mode**: Summarizes the entire conversation into a clean, professional markdown document, merging existing data with new insights.

---

## 6. Technical Implementation Notes
- **JSON Cleaning**: Always strip markdown code blocks (````json ... ````) from AI responses before parsing.
- **Context Efficiency**: Limit interaction history to the last 3-5 exchanges to stay within token limits and maintain focus.
- **Capability Switching**: Support both "Fast" (Flash Lite) for quick onboarding and "Pro" (Flash) for complex draft generation and profile updates.
