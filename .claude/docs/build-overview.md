# Aria Build Overview

## What We're Building

Aria is a live Agentforce ASA embedded in an Experience Cloud site. Authenticated diners can modify or cancel reservations via Aria's natural language interface. Aria calls a mock REST API (Apex class in the same org) via Named Credentials, grounds FAQ responses in Knowledge articles via Einstein Search Grounding, and hands off to a human agent via Omni-Channel when needed.

---

## Architecture

```
Experience Cloud (embedded chat)
        │
        ▼
  Agentforce ASA — Aria
  New Agent Builder + Script Builder
  Einstein Trust Layer (zero data retention, PII masking)
        │
   ┌────┴────────────────────────────────┐
   │                                     │
   ▼                                     ▼
Booking Management                Restaurant Information
Get / Modify / Cancel              Account (RT: Restaurant)
Reservation__c                     SOQL Agent Actions
via Flow-invocable Apex
→ Named Credential                    Platform FAQ
→ Mock Apex REST class            Knowledge + Einstein
        │                         Search Grounding
        ▼
  Escalation
  Omni-Channel warm transfer
  + Case creation fallback
        │
        ▼
  Data Cloud (read-only grounding)
  Unified diner profile context
```

---

## Data Model

| Object | Type | Purpose |
|---|---|---|
| Account (RT: Restaurant) | Standard | Restaurant records — hours, cuisine, policy, accessibility |
| Reservation__c | Custom junction | Links Contact ↔ Account, holds booking details + status |
| Contact | Standard + custom fields | Diners — Membership_Number__c, Loyalty_Tier__c, Dietary_Preferences__c |
| Case | Standard + custom fields | Escalation fallback — links to Reservation__c, stores transcript |
| Knowledge | Standard | FAQ/policy articles, Einstein Search Grounded |
| MessagingSession | Standard + custom fields | Carries Agentforce context variables from Experience Cloud session |
| Build_Task__c | Custom | Build orchestration state — do not edit manually |

---

## Agentforce Topics

| Topic | Auth Required | Key Actions |
|---|---|---|
| Booking Management | Yes | Get Reservation Details, Modify Reservation, Cancel Reservation |
| Restaurant Information | No | Get Restaurant Info (SOQL), Check Availability |
| Platform FAQ | No | Einstein Search Grounding over Knowledge articles |
| Escalation + Guardrails | — | Warm transfer, Case creation, Slack fallback |

---

## Context Variables (MessagingSession → Aria)

Aria never asks diners to identify themselves. Context is populated automatically via an Omni-Channel Flow when the chat session starts.

| Variable | Source | Used By |
|---|---|---|
| `{!$Context.IsAuthenticated__c}` | Experience Cloud session | Topic gate — Booking Management |
| `{!$Context.ContactId__c}` | Authenticated Contact record | Passed to all booking actions |
| `{!$Context.BookingReference__c}` | URL parameter (booking confirmation page) | Pre-fills booking reference slot |
| `{!$Context.LoyaltyTier__c}` | Contact.Loyalty_Tier__c | Cancellation retention logic (Platinum/Gold offers) |
| `{!$Context.MembershipNumber__c}` | Contact.Membership_Number__c | Identity grounding for Data Cloud |

---

## Build Phases & Task Owners

| Phase | Tasks | Owner | Dependencies |
|---|---|---|---|
| -1 Safety | TASK-BACKUP | Destiny | — |
| 0 Prerequisites | TASK-D0 (Knowledge + Search Grounding) | Destiny | BACKUP |
| 1 Data Foundation | TASK-D1 (objects + permission set) | Destiny | BACKUP |
| 1 Mock Data | TASK-Z1 (mock records — Zach reviews) | AI → Zach | D1 |
| 2 Integration | TASK-D2 (Mock API Apex) | Destiny | D1 |
| 2 Integration | TASK-D3 (Named Credential) | Destiny | D2 |
| 2 Integration | TASK-D4 (Flow-invocable actions) | Destiny | D3 |
| 3 Agentforce | TASK-D5 (agent + Omni Flow) | Destiny | D4 |
| 3 Agentforce | TASK-D6 (Booking Management topic) | Destiny | D5 |
| 3 Agentforce | TASK-D7 (Restaurant Information topic) | Destiny | D5 |
| 3 Agentforce | TASK-D8 (Platform FAQ topic) | Destiny | D5 + A1 |
| 3 Agentforce | TASK-D9 (Escalation + Guardrails) | Destiny | D5 |
| 4 Channels | TASK-D11 (Experience Cloud site) | Destiny | D5 |
| 4 Channels | TASK-D12 (Omni-Channel / Slack fallback) | Destiny | D5 |
| 4 Channels | TASK-D14 (Sofia Community user) | Destiny | D11 + Z1 |
| 5 Data Cloud | TASK-D13 (grounding — parallel) | Destiny | BACKUP |
| 6 Knowledge | TASK-A1 (articles — Adam reviews) | AI → Adam | D0 |
| 6 Knowledge | TASK-A2 (CTO prep + rubric — Adam reviews) | AI → Adam | D6–D9 |
| 7 Testing | TASK-T1–T3 (full test suite) | adlc-qa | D6–D9 + Z1 + A1 |
| 7 Testing | TASK-DEMO (pre-demo dry run) | adlc-qa | T1–T3 |

---

## Critical Path

```
BACKUP → D0 + D1 (parallel) → D2 → D3 → D4 → D5 → D6–D9 (parallel) → D11 → T1–T3 → DEMO
              ↑                                          ↑
           TASK-Z1                                   TASK-A1
     (Zach mock data review)                 (Adam Knowledge review)

Data Cloud (D13) — parallel with everything, not on critical path
```

---

## Escalation Matrix

| Trigger | Action |
|---|---|
| "human" / "agent" / "talk to someone" | Warm transfer |
| Cancellation outside policy window | Warm transfer + Case |
| Payment or billing request | Immediate warm transfer |
| Emotional distress keywords | Immediate warm transfer |
| Accessibility accommodation | Warm transfer with priority flag |
| Legal / discrimination claim | Immediate warm transfer + Case |
| No Knowledge answer after search | Escalate or create Case |
| Confidence below threshold after 2 clarification turns | Warm transfer + transcript |
| No agent available | Create Case (Priority=High), email diner, auto-route next business hour |

---

## Demo Script

| Step | Action | Expected Result |
|---|---|---|
| 1 | Sofia logs into Aria Dining Portal | Experience Cloud site loads |
| 2 | Navigates to booking confirmation page | Aria greets, booking reference pre-fills in chat |
| 3 | "I'd like to change my reservation to next Saturday at 7pm for 4 people" | Agent slot-fills, confirms, calls ModifyReservationAction, returns confirmation |
| 4 | "What's the cancellation policy if plans change?" | Knowledge-grounded response from Cancellation Policy article |
| 5 | "I need to speak to someone about a billing issue" | Immediate warm transfer, Case created with Priority=High and conversation transcript |

---

## Adding Requirements (Process)

If Zach or Adam has a new requirement:

1. **Submit** — Post in team Slack channel or message Destiny directly. Include: what, why, priority.
2. **Validate** — Destiny invokes `/aria-build-orchestrator`. Skill checks scope, conflicts, phase, dependencies.
3. **Draft** — Skill drafts the task spec and shows Destiny for approval.
4. **Commit first** — Skill updates the refs/ file + task registry, commits and pushes to GitHub.
5. **Salesforce second** — Only after the push succeeds, skill upserts the `Build_Task__c` record.
6. **Notify** — Slack notification sent with task ID and expected timeline.

See the orchestrator's "Requirement Intake & Skill Update Flow" section for the full collision handling procedure.
