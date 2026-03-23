# KeyValue App: AI Agent Functions Summary

The AI agent in the KeyValue app (powered by Gemini via `firebase_ai`) has access to the following function declarations (tools) to interact with the application state and assist the advisor:

## Client Onboarding & Creation
- **`update_client_preview`**: Updates the real-time client onboarding preview UI in the application. Used as the AI gathers information.
  - *Parameters*: `name`, `email`, `occupation`, `details`, `guidelines`
- **`create_client`**: Registers a new client and navigates the advisor to their newly created profile. Called once the core information (name, email, basic background) has been gathered.
  - *Parameters*: `name`, `email`, `occupation`, `details` (Markdown), `guidelines` (Markdown)

## Profile & Content Management
- **`update_profile`**: Updates a client's background profile.
  - *Parameters*: `customerId`, `updated_profile` (Full Markdown profile)
- **`update_guidelines`**: Updates the engagement guidelines for a specific client.
  - *Parameters*: `customerId`, `updated_guidelines` (Full Markdown guidelines)
- **`update_client_info`**: Updates the primary contact information for a client.
  - *Parameters*: `customerId`, `name`, `email`, `occupation`
- **`get_current_profile`**: Fetches the latest client data. Used for data safety before updating profiles or guidelines if the text isn't already in the AI's history.
  - *Parameters*: `customerId`

## Engagement & Outreach
- **`update_draft`**: Refines and updates an existing message draft for a client.
  - *Parameters*: `customerId`, `refined_draft`
- **`generate_outreach`**: Triggers the creation of a new proactive message draft for a client.
  - *Parameters*: `customerId`
- **`manage_schedules`**: Modifies the engagement schedules/cadences for a client.
  - *Parameters*: `customerId`, `action` (e.g., ADD/REMOVE_ALL), `cadenceValue`, `cadencePeriod`

## Navigation & UI Control
- **`navigate_to_client`**: Instructs the "Main Port" UI to navigate to and display a specific client's detail view.
  - *Parameters*: `customerId`
- **`list_clients`**: Instructs the UI to show the client dashboard, optionally applying a filter.
  - *Parameters*: `filter`
