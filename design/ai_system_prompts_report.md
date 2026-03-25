# AI System Prompts & Function Calls Report

This report documents the current state of AI system instructions, prompts, and tool definitions within the KeyValue application. It is intended to assist in investigating hallucinations and improving prompt quality.

## 🤖 Core AI Configuration

- **Model:** `gemini-2.5-flash` (Defined in `AiService.dart:43`)
  > [!WARNING]
  > The model name `gemini-2.5-flash` appears to be a typo or hallucination in the code. Standard Gemini models are `gemini-1.5-flash` or `gemini-2.0-flash-exp`. This may cause unexpected behavior if the secondary SDK treats it as a generic model.

- **System Instruction:** (Defined in `AiService.dart:130-142`)
  ```markdown
  Role: Expert "Intelligence Hub" assistant. 
  Context: You reside in the "AI Sidebar" and control the "Main Port" via tools.
  UI State: [Injected JSON]
  
  Mandatory Rules:
  1. **Notifications**: Explicitly tell the user what tool you called and what changed.
  2. **Data Safety**: Before updating profile/guidelines, call `get_current_profile` if the text isn't in your history. 
  3. **Proactivity**: Synthesize info into high-quality Markdown. Don't ask for wording; suggest it.
  4. **Onboarding**: Once you have gathered the name, email, and basic background, call `create_client` to automatically register the client and navigate to their new profile.
  5. **AI-Assisted Editing**: If the user prompt starts with "CONTEXT: Editing [TYPE]", prioritize refining that specific content using the appropriate tool.
  6. **Change Summaries**: When calling `update_profile` or `update_guidelines`, you MUST provide a concise one-sentence summary of what specifically was changed.
  ```

---

## 🛠️ Function/Tool Declarations

The model is equipped with the following tools (handled in `GlobalChatProvider._executeAiTool`):

| Function Name | Description | Key Parameters |
| :--- | :--- | :--- |
| `update_client_preview` | Updates real-time onboarding preview. | `name`, `email`, `occupation`, `details`, `guidelines` |
| `create_client` | Finalizes registration and navigates to profile. | `name`, `email`, `occupation`, `details`, `guidelines` |
| `update_profile` | Updates client background profile (Proposed). | `customerId`, `updated_profile`, `summary` |
| `update_guidelines` | Updates engagement guidelines (Proposed). | `customerId`, `updated_guidelines`, `summary` |
| `update_draft` | Refines a message draft. | `customerId`, `refined_draft` |
| `navigate_to_client` | Switches the UI to a specific client. | `customerId` |
| `list_clients` | Navigates to the Dashboard. | `filter` |
| `update_client_info` | Updates primary contact details. | `customerId`, `name`, `email` |
| `generate_outreach` | Manually triggers a new draft generation. | `customerId` |
| `get_current_profile` | Fetches the latest data for a client. | `customerId` |
| `manage_schedules` | Adds or removes engagement schedules. | `customerId`, `action`, `cadenceValue`, `cadencePeriod` |

---

## 📝 Task-Specific Prompts

### 1. General User Chat
- **Location:** `GlobalChatProvider.sendMessageStream`
- **Dynamic Context:** If the user is editing a field (e.g., a draft), the prompt is prefixed:
  ```markdown
  CONTEXT: Editing [TYPE]: "[CONTENT]"
  
  USER REQUEST: [USER_PROMPT]
  ```
- **Fallback Logic:** If cloud AI fails, it uses `generateOnDeviceResponse` (Android AICore or Chrome Prompt API).

### 2. Proactive Discovery (Draft Generation)
- **Location:** `AiService.generateDraftMessage`
- **Prompt:**
  ```markdown
  Draft a professional check-in message for ${customer.name}.
  Customer Background: ${customer.details}
  Engagement Guidelines: ${customer.guidelines}
  
  Return ONLY the message text. Do not include any other text or call any tools.
  ```
  > [!IMPORTANT]
  > This prompt explicitly forbids tool calling, which is good practice for simple "text-only" tasks to avoid hallucinated function calls.

### 3. Intelligence Hub (Profile Merging)
- **Location:** `AiService.updateCustomerDetails`
- **Prompt:**
  ```markdown
  Merge new info from the response into the current profile. Preserve Markdown.
  Profile: [CURRENT]
  Response: [INBOUND_SMS]
  
  Return the result as a JSON object with exactly two fields:
  1. "updated_profile": The full updated Markdown profile.
  2. "summary": A very brief (1 sentence) summary of what specifically changed or was added.
  
  JSON:
  ```

---

## 🔍 Hallucination Risks & Recommendations

1. **Brittle JSON Parsing:** `updateCustomerDetails` uses `indexOf('{')` to find JSON in the AI response. If the AI adds preamble text or provides malformed JSON, parsing will fail.
   - *Recommendation:* Use Gemini's **Constrained Output (JSON Mode)** or a schema-based response.

2. **UI Context Injection:** The entire `uiContext` is injected into the system instruction as a JSON string. If this context grows (e.g., listing all clients), it may distract the model.
   - *Recommendation:* Flatten the context or only include relevant IDs/slices.

3. **Inconsistent Editing Logic:** The app uses both Tool Calling (via `update_profile`) and Raw JSON generation (via `updateCustomerDetails`) for similar tasks.
   - *Recommendation:* Unify all state changes to use Function Calling.

4. **Model Name Ambiguity:** As noted, `gemini-2.5-flash` is likely incorrect.
   - *Recommendation:* Verify and correct the model identifier to a supported production version (e.g., `gemini-1.5-flash`).
