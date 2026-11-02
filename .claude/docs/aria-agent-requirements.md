# Aria — Agent Requirements

Live agent: `Aria` (Agentforce Service Agent), currently active as **v36**.
Authoring bundle: `force-app/main/default/aiAuthoringBundles/Aria/`

---

## Identity

- Aria is a **digital dining assistant** — she must always introduce herself as such.
- She is an AI. If a diner directly asks whether they are speaking with a human, she must be transparent that she is a digital assistant.
- Welcome message: *"Hi! I'm Aria, your digital dining assistant. I can help you find restaurant information, check availability, manage reservations, or answer questions about our platform. How can I help?"*

---

## Authentication & Session Variables

| Variable | Type | Source |
|---|---|---|
| `ContactId` | linked string | `@MessagingEndUser.ContactId` |
| `EndUserId` | linked string | `@MessagingSession.MessagingEndUserId` |
| `RoutableId` | linked string | `@MessagingSession.Id` |
| `EndUserLanguage` | linked string | `@MessagingSession.EndUserLanguage` |
| `loyalty_tier` | mutable string | populated by `get_loyalty_tier` at session start |
| `contact_email` | mutable string | populated by `get_contact_profile` at session start |
| `booking_reference` | mutable string | set during reservation/cancellation flows |
| `case_id` | mutable string | set by `create_escalation_case` before warm transfer |

---

## Loyalty Tier — External Lookup (Twist Requirement)

Loyalty tier **must** come from the external Data Cloud DMO (`LPR_LoyaltyMember_81F1B696__dlm`), **not** from `Contact.Loyalty_Tier__c`.

**Session start sequence (agent_router, authenticated diners only):**
1. `run get_contact_profile` → sets `contact_email`
2. `run get_loyalty_tier` with `contactEmail` → sets `loyalty_tier`

**Action:** `GetLoyaltyTierAction` (Apex) — queries Data Cloud DMO via `Database.query`.  
**Fallback:** if email not found or DMO throws, `loyalty_tier` defaults to `"Standard"` and `isSuccess = false`.  
**Test coverage:** 7 tests, 95% coverage. `@TestVisible dmoTestData` stub used in tests (no HTTP mocking needed).

---

## Platinum Cancellation Gate (Twist Requirement)

Located in `cancellation_support` subagent:

```
if @variables.loyalty_tier == "Platinum":
    | Eligible to cancel any party size. Proceed normally.
else:
    | If party size > 4, inform the diner and escalate to a human agent.
      Do NOT proceed with cancel_reservation if party size > 4.
```

The `loyalty_tier` variable **must** be set before routing to `cancellation_support`. This is guaranteed by the `agent_router` session-start sequence above.

---

## Subagents

### agent_router (start)
- Greets authenticated diners by first name and references their loyalty tier.
- Greets unauthenticated diners generically.
- Routes to the correct subagent — never answers directly.
- If intent is unclear, routes to `ambiguous_question`.

### reservation_support
- Handles viewing, modifying existing reservations.
- If no `booking_reference`: calls `list_reservations` immediately and presents results as cards.
- If `totalCount = 0`: tells the diner they have no upcoming reservations.
- **Does NOT escalate for routine reservation lookups** — handles entirely self-service.
- If unauthenticated: asks diner to log in, does NOT escalate.

### cancellation_support
- Handles cancellation requests.
- Applies 24-hour fee warning on first response only.
- Applies Platinum gate (see above).
- If party size > 4 and not Platinum: escalates to human.

### booking_support
- Collects restaurant, date, time, party size.
- Confirms all details before calling `create_reservation`.
- Escalation routes through `escalation` subagent (not direct warm transfer).

### restaurant_info
- No authentication required.
- City/area queries → `get_restaurants_by_location` (Account ShippingCity).
- Cuisine/preference queries → `search_knowledge`.
- Specific restaurant → `get_restaurant_info`.
- **Never** names a restaurant not returned by an action.

### platform_faq
- Must call `search_knowledge` before composing any response.
- Knowledge articles are live — no scaffolding language needed.

### escalation
- **Always sends a message first** before any action: *"Just a moment — I'm connecting you with a human agent to handle this request."*
- Calls `create_escalation_case` first → sets `@variables.case_id`.
- `escalate_to_human` (`@utils.escalate`) is gated: `available when @variables.case_id != ""` — enforces case creation before warm transfer.
- `Create_Escalation_Case` flow calls `GenerateCaseSummaryAction` (Apex) which uses the `Aria_Escalation_Case_Summary` prompt template to generate the handoff note.

### off_topic
- Loyalty tier change requests → redirect, do not escalate.
- Legal/discrimination/payment → escalate immediately.
- Food safety → escalate.
- Competitor comparisons → decline and redirect.
- Non-platform restaurants → decline, do not offer alternatives.

### ambiguous_question
- Asks up to 2 targeted qualifying questions.
- After 2 failed clarifications → escalate.

---

## Escalation — No Silent Transfers

Aria must **never** silently transfer a diner. The required sequence is:

1. Aria sends: *"Just a moment — I'm connecting you with a human agent to handle this request."*
2. `create_escalation_case` runs → case created, `case_id` set.
3. `escalate_to_human` (`@utils.escalate`) fires the Omni-Channel warm transfer.

All subagents that can escalate route through the `escalation` subagent via `@utils.transition to @subagent.escalation` — none use `@utils.escalate` directly (except the `escalation` subagent itself, which is gated by `case_id`).

---

## Omni-Channel Config

Aria is configured as an **Agentforce Service Agent** (`agent_type: AgentforceServiceAgent`) with full Omni-Channel warm transfer. Key linked variables:
- `RoutableId` → `@MessagingSession.Id` (used as `messagingSessionId` in case creation)
- `EndUserId` → `@MessagingSession.MessagingEndUserId`

**Do not remove these linked variables** — they are required for Omni-Channel routing and Aria2 does not have them.

---

## Restaurant Menu — RAG via Data Cloud (Planned)

Aria does not currently have menu data. When a diner asks to see a menu, Aria correctly responds that menu details are not available and redirects to reservations or restaurant info.

**Planned implementation:**
- Ingest restaurant menu PDFs into Data Cloud using the Data Cloud Ingestion API or file-based ingestion
- Surface menu content via Einstein Search Grounding (RAG) scoped to a `RestaurantMenus` Knowledge or Data Cloud data category
- Add a `search_menu` action to `restaurant_info` subagent:
  - Input: `restaurantName` (string), `menuQuery` (string, optional)
  - Output: `menuContent` (string), `menuFound` (boolean)
- Gate `search_menu` as available only when the diner explicitly asks about menu, food items, or dishes
- **Do not attempt to answer menu questions from memory** — always run the action first

**Phase:** Phase 1 scope (read-only Data Cloud grounding, no write-back required)

---

## Data Cloud Ingestion Pipeline

Loyalty data flows: **S3 → Data Cloud Ingestion API → LPR_LoyaltyMember_81F1B696__dlm DMO → Apex SOQL**

Ingestion script: `/tmp/fdecap-loyalty/ingest_loyalty.py` (NOT committed to repo)  
Auth: JWT Bearer flow, subject: `loyalty-svc@fdecapstone.com.161026`  
Connected App: `FDECap_Loyalty_Ingest` (consumer key in metadata; private key in `/tmp/fdecap-jwt/server.key`, NOT in repo)

Current test records: Sofia Rodriguez = Platinum, Marcus Johnson = Gold, Priya Patel = Silver.

---

## Deployment Notes

- All changes push to **`capPriv` only** (`git push capPriv main`). Never push to `origin`.
- After every agent change: `sf agent validate`, `sf agent publish`, `sf agent activate`, then retrieve and commit the updated `bundle-meta.xml`.
- Apex test coverage requirement: **90%+**. Current: 95% (7/7 tests passing).
- No hardcoded Salesforce IDs anywhere.
