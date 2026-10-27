# Aria — Technical Considerations, Security, Ethics & Trust

---

## How to Read This Document

Each section is split into two columns of thought:

- **Platform-Provided** — capabilities Salesforce/Agentforce delivers out of the box; we configured or enabled them, but did not build the underlying mechanism.
- **Custom-Built (and Why)** — things we specifically designed and implemented for this project, and the reasoning behind the choice.

---

## Architecture & Platform

### Platform-Provided

- **Agentforce Agent Script (ASA)** — the scripting runtime, subagent graph execution engine, and LLM reasoning loop are all native to the Agentforce platform. We author `.agent` files; Salesforce runs them.
- **Omni-Channel routing** — queue-based work routing, MessagingSession lifecycle, and warm transfer mechanics are all OOTB. We configured a "Table Topper Queue" and a RoutingFlow; we did not build the routing engine.
- **Experience Cloud session context** — `ContactId` and `RoutableId` are injected into the session by the platform's messaging infrastructure at session start, not by our code.
- **Einstein Search Grounding** — the platform indexes published Knowledge articles and injects relevant excerpts into the agent's reasoning context automatically. We publish articles; the platform grounds the LLM.
- **Einstein Trust Layer** — zero data retention, PII masking, toxicity detection, and the audit trail are all platform-enforced policies. We opted in; Salesforce enforces them.
- **Data Cloud (Phase 1)** — the read-only grounding pipeline and the ADL indexing infrastructure are platform services. We provision a library and wire it into the `knowledge:` block.
- **Named Credentials** — the secure credential store and callout routing are managed by Salesforce. We create Named Credential records; no secret ever appears in our code.

### Custom-Built (and Why)

- **`Aria_Context_Variable_Mapping` Flow** — maps `ContactId` and `RoutableId` from the inbound MessagingSession into agent-readable variables at session start. Built because the platform injects these at the messaging layer, not directly into agent variables; this bridge was required to gate private actions on authentication state.
- **`ServiceAgentEscalationFlow` (RoutingFlow)** — creates a Case record, links the MessagingSession to it, then routes to the human queue. Built because a raw `@utils.escalate` alone does not create a paper trail; diners need a ticket number and agents need full context on pickup.
- **`Aria_Escalation_Case_Summary` Prompt Template** — generates a structured handoff note (ESCALATION SUMMARY, ISSUE, RESOLUTIONS OFFERED, ESCALATION REASON) injected into the Case before transfer. Built to solve the cold-handoff problem — without it, the human agent receives a session with no context.

---

## Data Model

### Platform-Provided (OOTB Objects Used As-Is)

- **`Contact`** — standard object; used as the diner identity record. No schema changes beyond relationship fields.
- **`Case`** — standard object; used as the escalation ticket. Added a custom Lookup to `Reservation__c` and a `Conversation_Transcript__c` long-text field — everything else is native.
- **`Knowledge`** — standard object; used for restaurant guides and platform policy articles. Used OOTB with standard data categories; no schema changes.
- **`Account` (Restaurant record type)** — standard object with a custom record type applied. No new fields; the record type distinction is configuration, not development.

### Custom-Built (and Why)

- **`Reservation__c`** — custom junction object with two Master-Detail relationships: `Account` (restaurant, the primary master) and `Contact` (diner). The junction models a many-to-many relationship — one diner can hold reservations at multiple restaurants; one restaurant can have many reservations from many diners. Built custom because no standard Salesforce object models a diner-to-restaurant booking. Using `Opportunity` or `Order` would have required aliasing standard fields (Amount, Stage, OrderedDate) to hold reservation semantics, violating the intent of those objects and complicating report filtering.

  The double Master-Detail design was chosen deliberately:
  - **Cascade delete** — deleting a restaurant (`Account`) or a diner (`Contact`) automatically deletes their associated reservations; no orphan records.
  - **Ownership rollup** — record ownership follows the primary master (`Account`), keeping org-wide defaults clean.
  - **Native sharing via SharingSet** — because the diner's `Contact` is in the Master-Detail chain, Experience Cloud sharing rules can grant the diner access to their own reservations without custom sharing logic.
  - **Roll-up summary fields** — both the restaurant and the diner can carry native count/date roll-ups (e.g., total reservations, most recent visit) without Apex.
- **`Build_Task__c`** — custom object for build orchestration state. Built to track task completion across sessions in a shared org without relying on external project management tools.
- **Individual Account per diner (`Customer` record type on Account)** — one Account per Contact, required for Experience Cloud sharing. Built because Experience Cloud's standard SharingSet mechanism requires each portal user's Contact to belong to a dedicated Account; without this, reservation records cannot be shared to diners via OOTB rules.

### Why These Objects, Not Others

The data model deliberately reuses OOTB objects where semantic fit is good (`Contact` for people, `Case` for support tickets, `Knowledge` for articles) and builds custom only where there is no OOTB equivalent (`Reservation__c` as a restaurant booking junction). This approach:

- Keeps permission management on standard profiles/permsets
- Leverages native FLS/OWD/SharingSet without custom logic
- Ensures Agentforce actions can query standard objects directly without custom wrappers

---

## Time Zone Handling

### Platform-Provided

- **Salesforce org time zone** — the org has a default time zone used for DateTime display in the UI. All `DateTime` fields (e.g., `CreatedDate` on `Case`) are stored in UTC and converted automatically by the platform for screen rendering.
- **User record time zone** — authenticated Experience Cloud users have a `TimeZoneSidKey` on their `User` record; the platform applies it when rendering DateTime fields natively in UI components.

### Custom-Built (and Why)

- **Restaurant hours stored as plain text** — `Operating_Hours__c` on `Account` and hours sections in Knowledge articles are free-text strings (e.g., "Mon–Fri 11:00 AM – 9:00 PM"). No time zone conversion is applied because these represent the restaurant's local hours — they are always correct relative to the restaurant's location and are not stored as `DateTime` values.
- **Reservation time stored in restaurant local time** — `Reservation_Time__c` on `Reservation__c` is a `Time` field, not a `DateTime`. It represents the local time at the restaurant. Aria presents it directly (e.g., "7:00 PM") without conversion. This is intentional: a diner booking a table at 7:00 PM in Chicago cares about Chicago's 7:00 PM, not a UTC-equivalent.
- **No diner time zone conversion in agent responses** — Aria does not detect or apply the diner's browser/device time zone when presenting reservation times or restaurant hours. This is a known gap: a diner in a different time zone from the restaurant could misread a time if they assume it is in their local zone. Mitigation: all reservation confirmations include the restaurant's city alongside the time, giving the diner enough context to identify any offset (e.g., "7:00 PM at The Golden Fork in Chicago").
- **Known limitation — international expansion** — the current model works correctly for domestic US use where diner and restaurant are typically in similar or adjacent time zones. If TableTopia expands to multi-timezone or international markets, `Reservation_Time__c` should be converted to a `DateTime` field (stored in UTC) and a restaurant-timezone field added to `Account`, with explicit conversion in all Apex actions and agent responses.

---

## Security

### Platform-Provided

- **Einstein Trust Layer enforcement** — PII masking and zero data retention happen at the platform layer; our agent cannot disable them.
- **FLS and CRUD enforcement** — Apex `with sharing` + standard Salesforce FLS means the platform enforces field-level and record-level access automatically. Our code does not need to re-implement authorization checks for standard object access.
- **Experience Cloud guest user isolation** — the platform blocks unauthenticated access to records outside of guest user sharing rules. `Reservation__c` is not in any guest sharing rule by design.
- **Named Credential callout security** — secrets are stored in the platform's encrypted credential store; our code never sees them.

### Custom-Built (and Why)

- **`verifyOwnership()` in reservation Apex** — explicitly checks that `Reservation__c.Diner__c` matches the session `ContactId` before any read or write. Built because standard FLS does not prevent a diner who knows another diner's booking reference from accessing that record — ownership verification is a business-logic layer above object permissions.
- **Authentication gate in agent instructions** — all private subagents (`reservation_support`, `cancellation_support`) check `@variables.ContactId` before calling any action. Built because the platform injects `ContactId` but does not automatically block action invocations; the gate must be expressed in agent logic.
- **No dynamic SOQL anywhere** — all queries use bind variables. Built as a deliberate coding standard to eliminate injection surface entirely.

---

## Ethics

### Platform-Provided

- **Prompt injection detection** — the platform's built-in Einstein safety classifier routes known injection patterns to a `Prompt_Injection` topic automatically.
- **Toxicity detection** — content moderation on LLM outputs is an Einstein Trust Layer service; Aria cannot produce toxic content that bypasses it.

### Custom-Built (and Why)

- **AI disclosure** — Aria identifies itself as an AI assistant and never impersonates a human. This is an explicit instruction in the agent, not a platform-enforced rule. Built because Agentforce does not mandate AI disclosure by default; we added it to meet our transparency standard.
- **Escalation always available** — every subagent offers a path to a human. Built deliberately: the platform allows agents to close conversations without escalation; we chose not to use that capability.
- **Scope boundary instructions (`off_topic` subagent)** — Aria declines competitor comparisons, non-platform restaurant recommendations, loyalty tier manipulation, and discount requests. Built as explicit instructions because the LLM would otherwise answer these questions from general training knowledge.
- **Restaurant data sourced from Knowledge only** — the CRITICAL instruction in `restaurant_info` forbids naming any restaurant from memory; all restaurant details must come from `search_knowledge` or `get_restaurant_info`. Built to prevent hallucinated restaurant recommendations, which would be a direct trust failure for diners making reservations.
- **Consistent policy application** — cancellation fee warnings apply based on time window, not diner tier or agent discretion. Built into action logic so the agent cannot skip the warning.

### Accessibility

- **What the platform provides** — Experience Cloud generates accessible HTML for the chat widget. Omni-Channel messaging is screen-reader compatible.
- **What we built** — Knowledge article content is the authoritative source for restaurant accessibility information (wheelchair access, parking, entrance steps). When an article incorrectly described The Bellevue Table as accessible, we corrected it — because inaccurate accessibility information is a direct harm to diners who rely on it. We treat article accuracy as an ethical obligation, not just a data quality issue.

---

## Trust

### Platform-Provided

- **Einstein Trust Layer audit trail** — every LLM call is logged automatically; we did not build the logging.
- **MessagingSession linkage** — the platform records the full conversation in the MessagingSession object; we did not build the transcript store.
- **Case record as audit artifact** — the standard Case object provides a durable, auditable record of every escalation. We configured it; the platform persists it.

### Custom-Built (and Why)

- **Structured escalation handoff note** — the `Aria_Escalation_Case_Summary` prompt template produces a consistent, human-readable summary in every Case. Built because unstructured transcript dumps are not actionable for human agents at queue pickup.
- **Regression test suite** (`Aria-testing-center.yaml`, `Aria-restaurant-info-conversation.yaml`) — 20+ utterance-level and conversation-level tests covering routing, action invocation, anti-hallucination, authentication gating, and safety probes. Built because the platform's Testing Center provides the infrastructure but not the test cases; test coverage is our responsibility.
- **Knowledge article review process** — all 56 Knowledge articles are reviewed before going Online. Built as a team process because grounding accuracy depends entirely on article quality; the platform grounds on whatever is published.
- **`Build_Task__c` version tracking** — each agent version is tied to a build task, providing a lightweight audit trail of what changed and when. Built because agent versions are published to the org without change descriptions; we needed a human-readable record.

---

## Why We Built What We Built Custom: Summary

| Custom Component | Why Not OOTB |
|---|---|
| `Reservation__c` | No standard booking object exists; double Master-Detail junction enables cascade delete, native sharing via SharingSet, and roll-up summaries on both parent objects |
| Individual Account per diner | Required by Experience Cloud SharingSet for record-level access |
| `verifyOwnership()` in Apex | FLS does not prevent cross-diner access by booking reference |
| `Aria_Context_Variable_Mapping` | Platform injects ContactId at messaging layer, not into agent variables |
| `ServiceAgentEscalationFlow` | `@utils.escalate` alone creates no Case and no paper trail |
| `Aria_Escalation_Case_Summary` | Cold handoff to human agent; unstructured transcript is not actionable |
| Authentication gate in agent instructions | Platform injects ContactId but does not auto-block action invocations |
| Anti-hallucination CRITICAL instruction | LLM will name restaurants from training data if not explicitly blocked |
| `off_topic` scope boundary instructions | LLM answers out-of-scope questions by default; refusal must be instructed |
| Regression test suite | Testing Center infrastructure provided; test cases are our work |
