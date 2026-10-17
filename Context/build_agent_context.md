# Build Agent Context
## Intelligent Diner Support Agent — Team 4 Capstone

This file captures all architectural decisions, constraints, confirmed details, and known gaps for the build agent working on this Agentforce Capstone project.

---

## What We Are Building

An Agentforce Autonomous Service Agent (ASA) named **Aria** for an online hospitality and reservations platform. The agent handles diner support for booking modifications, cancellations, restaurant information lookup, and escalation to human agents.

This is a **Salesforce Professional Builder Onboarding Capstone** project. The final deliverable is a **live demonstration** presented to an Evaluation Panel role-playing as a CTO at UAT stage. The demo org is a **sandbox environment** — deploying to production is not required.

---

## Team

- Destiny McKee — Lead Forward Deployed Engineer, Salesforce
- Adam Barr — Principal Deployment Strategist, Salesforce
- Zach Copman — Principal, Forward Deployed Engineer, Salesforce

---

## Demo Org Test User

Use these credentials when interacting with agents in the demo org:

- **Customer name:** Sofia Rodriguez
- **Email:** sofiarodriguez@example.com
- **Membership number:** 10008155

---

## Confirmed Salesforce Products in Use

All product names below are verified. Do not substitute or invent alternatives.

- **Agentforce (New Agent Builder + Agent Script / Script Builder)** — primary build tool. Script Builder is the default. Custom Apex or Flow actions are valid additions but do not replace Script Builder.
- **Einstein Trust Layer** — AI security layer. Covers zero data retention, PII masking, toxicity filtering, input/output filtering. Prompt injection is blocked at the model layer.
- **Salesforce Knowledge** — KB articles grounded via Einstein Search Grounding. This is the primary data source for FAQ and restaurant policy responses.
- **Salesforce Omni-Channel** — warm transfer mechanism for human escalation.
- **Experience Cloud** — diner session authentication (OAuth token).
- **Data Cloud** — unified diner profiles. Phase 1: read-only grounding. Phase 2: full personalization.
- **MuleSoft** — production API integration layer. In demo org, use mocked REST endpoint via Named Credential.
- **Salesforce Flow** — wraps write operations to external reservation system as Flow-invocable Apex actions.
- **Apex** — REST callout logic for reservation modification and cancellation.
- **Named Credentials** — all external API calls. No hardcoded credentials anywhere.
- **Permission Sets** — least-privilege scoping for agent actions.

**Do NOT use or reference:**
- Salesforce Guardian (not a real product)
- Any product name you cannot verify

---

## Agent Structure

### Agent Name
Aria — Intelligent Diner Support Agent

### Agent Type
Autonomous Service Agent (ASA), Live channel

### Topics and Actions

| Topic | Actions | Read/Write | Visibility |
|-------|---------|------------|-----------|
| Booking Management | Get Reservation Details | Read | Private (authenticated) |
| Booking Management | Modify Reservation | Write | Private (authenticated) |
| Booking Management | Cancel Reservation | Write | Private (authenticated) |
| Restaurant Information | Get Restaurant Info | Read | Public |
| Restaurant Information | Check Availability | Read | Public |
| Platform FAQ | Search Knowledge Base | Read | Public |
| Escalation | Transfer to Human Agent (Omni-Channel) | System | Private |
| Escalation | Create Case (fallback) | Write | Private |

### Agentic Design Pattern
Reactive Agent. Intent classification → slot filling (clarification turns) → action execution → outcome confirmation. Max 2 clarification turns before escalation offer.

---

## Data Model

Custom objects required:
- `Reservation__c` — stores booking records (date, time, party size, restaurant, status)
- `Restaurant__c` — stores restaurant profile data (hours, location, policies, menu info)

Standard objects used:
- `Contact` — diner identity
- `Case` — escalation fallback when no human agent available
- `Knowledge` — KB articles for FAQ and grounding

---

## Integrations

### Reservation System API
- Protocol: REST/JSON
- Auth: OAuth 2.0 via Named Credential
- In demo org: mocked REST endpoint simulating create/read/update booking operations
- In production: MuleSoft integration layer
- Wrapped in: Flow-invocable Apex action

### Restaurant Data
- Source: Restaurant__c CRM records and/or Salesforce Knowledge articles
- Note: A separate "Restaurant Data API" was considered but is not confirmed. Use CRM records and Knowledge as the primary sources in the demo org.

### Omni-Channel
- Used for warm transfer to human agents
- Human agent desktop receives: full conversation transcript, diner Contact record, active Reservation__c record, issue classification label, recommended next action

### Data Cloud
- Phase 1: read-only. Provides diner profile context (booking history, preferences, loyalty tier) for grounding.
- Phase 2: active personalization, loyalty program integration

---

## Escalation Logic

Escalation triggers in order of priority:

1. No answer found after Knowledge article search → escalate to live agent or create support ticket
2. Agent confidence below threshold after 2 clarification attempts → warm transfer + transcript
3. Diner explicitly requests human → warm transfer + transcript
4. Cancellation outside policy window (requires manager approval) → warm transfer + Case
5. Payment dispute or billing request → immediate warm transfer
6. Emotional distress signals → immediate warm transfer
7. Accessibility accommodation request → warm transfer with priority flag
8. Legal, safety, or discrimination claim → immediate warm transfer + Case

Fallback when no human agent available: create Case with Priority = High, notify diner via email, auto-route to queue on next business hour.

---

## Guardrails

Off-limits topics (configure as guardrail nodes in Script Builder):
- Food safety and health complaints
- Legal threats and discrimination claims
- Competitor platform comparisons
- Any request outside hospitality and booking domain

Actions requiring human approval:
- Cancellations outside policy window
- Account-level changes (email, password)

Agent response for out-of-scope: "That's outside what I can help with today, but I can connect you with our support team."

---

## Security Requirements

- Einstein Trust Layer enabled on all LLM interactions
- Zero data retention — no diner PII in AI inference logs
- Named Credentials for all external callouts — no hardcoded secrets
- Permission Sets scoped to minimum-necessary record access
- Write actions require authenticated diner session — no anonymous writes
- RAI Governance: aligns with Salesforce Acceptable Use Policy (AUP)
- Ethics by Design: Consequence Scanning applied to identify bias, privacy, and misuse risks
- Human-in-the-Loop (HITL): no fully autonomous decisions on policy exceptions or sensitive topics

---

## Testing Requirements (from Capstone Rubric)

The rubric scores testing across functional, edge, regression, multi-turn, perturbation, and adversarial dimensions. Aim for Level 3+ (Intermediate).

Required test types:
- **Unit tests:** one per topic confirming correct routing
- **Edge tests:** cancellation at policy boundary, ambiguous booking requests
- **Regression tests:** re-run after every Script Builder update
- **Multi-turn tests:** agent maintains state across conversation turns
- **Perturbation tests:** rephrase same intent 5 ways, validate consistent resolution
- **Adversarial tests:** prompt injection, jailbreak patterns, off-topic probing, emotional escalation
- **Guardrail tests:** confirm guardrail fires correctly for each off-limits topic

Reference Splunk trace for debugging and optimization where available.

---

## Confirmed Metrics (from Use Case Brief)

Only use these metrics — do not invent additional numbers:

- Response time for common requests: down 25%
- First-contact resolution rate: above 80%
- FTE deflection of inbound diner support volume: 40 to 50%
- DSAT for automated interactions: measurable improvement vs. baseline
- Booking conversion: increase during initial deployment (baseline TBD at launch)
- Phase 2: increase repeat bookings and drive additional annual revenue via upselling and cross-selling

**Do NOT cite:** specific time benchmarks (under 60 seconds, under 2 minutes, 24/7) unless you can source them. These were removed from the brief for lack of verified sourcing.

---

## Metrics Sourcing Notes

- 40-50% FTE deflection: sourced from Salesforce State of Service reports. Cite with care — pull the current report for a specific number.
- Agentforce guided design / clarification loop limits: referenced in Salesforce Help documentation and Trailhead under Agentforce design guidance.

---

## Known Gaps / Open Questions

- **Restaurant data source:** confirmed as Salesforce Knowledge + Restaurant__c records for demo org. A separate external Restaurant Data API was scoped but not confirmed. Resolve before building.
- **Loyalty program integration:** Phase 2 roadmap item. Notes suggest loyalty tier-based discounting as a retention strategy before cancellation escalation (Platinum: free, Gold: discounted). Architecture not yet designed.
- **Payment processing:** removed from agent scope. Not handled by agent — escalate immediately.
- **Consumption model:** Flex Credits selected. Team should be prepared to explain why Flex Credits fits vs. outcome-based or AELA in CTO Q&A.

---

## Capstone Evaluation Rubric Summary

Scored across 6 areas. Aim for Level 3 (Intermediate) or above on each.

1. **Use Case Identification and Relevance** — real-world business challenge, quantifiable KPIs, persona storytelling
2. **Solution Design and Walkthrough** — functional New Agent Builder with Agent Script, agentic design pattern named, API integrations articulated, AIforce addressed
3. **Testing Suite** — functional, edge, regression, multi-turn, perturbation, adversarial
4. **Security Measures** — Einstein Trust Layer applied and explained, RAI Governance, HITL
5. **Business Impact and Consultative Readiness** — KPIs, consumption model, roadmap, deployment strategy
6. **Strategic Presentation and Communication** — CTO-ready, each team member has a distinct role

Passing threshold: 50% overall (Level 2). Standard expected: Level 3.

---

## Momentum Customer Context

**OpenTable** — hospitality reservations platform. Deployed "ASA (Live) | Restaurant Agent" for AQWK (Q&A, ticket creation, deflection scoring, lead qualification). Failure modes: not returning answers, making stuff up, not escalating when instructed. Directly mirrors this use case.

**Smartsheet** — work management platform. Deployed "In-app Service Agent (ASA)" for Q&A, Case Management, Escalation. Failure modes: unable to escalate to live agent, AQWK RAG issue producing made-up URLs.

Both failure modes are solved by: (1) Einstein Search Grounding on specific Knowledge articles, (2) explicit escalation triggers with tested conditions.
