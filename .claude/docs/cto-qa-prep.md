# CTO Q&A Prep — Aria (Intelligent Diner Support Agent)

Prepared for the FDE Capstone evaluation panel. Adam Barr to review and refine before presentation.

---

## Q1: Why Agentforce over a cheaper chatbot (e.g., Intercom, Drift, or a custom GPT)?

**Answer:**

Agentforce is not a chatbot layer bolted onto Salesforce — it is natively embedded in the CRM data model. That distinction matters in four concrete ways:

1. **No ETL, no sync lag.** Agentforce queries `Reservation__c`, `Account`, and `Contact` records directly via SOQL at runtime. A third-party chatbot requires either a custom integration or a data copy, both of which introduce latency, drift, and additional failure points.

2. **Einstein Trust Layer protects diner data.** Every LLM call goes through Salesforce's zero-data-retention gateway: the model never stores conversation content, and PII (names, emails, phone numbers) is masked before the prompt leaves the org. Third-party chatbots route data through external model providers under their own retention and privacy policies — creating legal and reputational exposure that the platform operator inherits.

3. **Omni-Channel warm transfer is native.** When Aria escalates, it hands off to a live agent in the same Diner Support queue that handles email and phone, with the full conversation transcript pre-attached to the Case. Intercom and Drift require custom webhook integrations to achieve partial parity with this, and they cannot natively route into Salesforce queues.

4. **Flex Credits model — no per-seat AI licensing.** Agentforce is priced per conversation (credit), not per seat. A restaurant platform with seasonal demand spikes does not pay for idle capacity. Custom GPT wrappers still require API token cost management, infrastructure hosting, and separate CRM integration work.

Built-in audit trail: every agent action — query executed, modification applied, escalation triggered — is logged as a Salesforce platform event. This is not an add-on; it is the default behavior of the CRM. No comparable out-of-the-box audit exists for third-party chatbots.

---

## Q2: What is the ROI timeline?

**Answer:**

**Hard cost baseline.** Industry benchmarks for human-handled live chat in hospitality put the fully-loaded cost per interaction at $8–$15 (agent time, workforce management overhead, training amortization). For a platform handling 5,000 diner contacts per month, that is $40,000–$75,000/month in support labor.

**Deflection target.** Tier-1 queries — reservation status, modification requests, restaurant hours/policy — represent roughly 65–70% of inbound volume based on typical hospitality support data. Agentforce deflection rate targets for this category are 60–70%, which is achievable once Knowledge grounding is tuned and the booking modification flow is stable.

**Agentforce cost per conversation.** Flex Credits list price is approximately $0.10–$0.25 per conversation. At $0.25 and 5,000 monthly contacts with 65% deflection: 3,250 deflected conversations × $0.25 = $812.50/month in AI cost. Compared to $26,000–$48,750 in human handling cost for the same volume, the savings are an order of magnitude.

**Breakeven math (conservative).** Assume implementation cost of $150,000 (platform configuration, integration, testing) and $812.50/month in ongoing AI credits. Monthly savings from deflection: ~$30,000 (midpoint of range). Breakeven: 5 months.

**Soft ROI factors not captured in that math:**
- 24/7 availability without overnight staffing premiums
- Consistent policy application — Aria applies the same cancellation policy to every diner, every time
- Modification handling speed — sub-30-second resolution vs. 4–8 minute average for human handling
- CSAT lift from instant response availability (industry data shows 15–20% CSAT improvement for instant-response channels vs. queued human chat)

---

## Q3: What is the Phase 2 roadmap?

**Answer:**

Phase 1 (current build) establishes the core booking management and support loop with a mock API backend. Phase 2 priorities, in implementation sequence:

1. **Data Cloud activation for proactive re-booking.** Phase 1 uses Data Cloud in read-only grounding mode. Phase 2 activates segments: when a restaurant cancels service for a date, Data Cloud identifies affected Reservation__c records and triggers a proactive outreach flow via Aria — offering alternative dates or a refund before the diner contacts support. This converts a reactive support cost into a proactive retention action.

2. **MuleSoft real API integration replacing the mock Apex layer.** The current Named Credential + Apex REST mock simulates a real reservation management system. The architecture is intentionally production-ready: swapping in the MuleSoft endpoint requires only a Named Credential update and no agent script changes. Phase 2 wires to the actual reservation platform API.

3. **Multi-language support via locale detection.** Experience Cloud sessions expose browser locale. Phase 2 routes Spanish and French speakers to locale-specific Knowledge article sets and uses Agentforce's multilingual response capability. Initial rollout: Spanish and French, covering the two largest non-English diner segments in the target market.

4. **Loyalty-tier personalization.** Platinum-tier diners (identified via Contact field on authenticated session) receive proactive upgrade offer prompts during modification conversations — e.g., "Your original table was for 4; we have a private dining room available for the same date." This is a new Aria subagent with its own slot-filling flow.

5. **SMS and WhatsApp channel via MIAW (Messaging for In-App and Web).** The current surface is Embedded Messaging on the Experience Cloud site. Phase 2 extends to SMS and WhatsApp via Salesforce's MIAW channel configuration — no agent script changes required, channel configuration only.

---

## Q4: How does Responsible AI governance work here?

**Answer:**

Governance operates at three levels: platform, data, and process.

**Platform level — Einstein Trust Layer:**
- **Zero data retention:** Conversation content is never persisted in the LLM provider's infrastructure. The Trust Layer gateway intercepts every prompt, forwards it to the model, and discards the payload after the response is returned. Salesforce holds no LLM training rights on org data.
- **PII masking:** Before any prompt reaches the model, the Trust Layer identifies and masks PII tokens — names, email addresses, phone numbers, reservation identifiers. The model sees placeholder tokens; the response is de-masked on return. This is enforced at the gateway, not at the prompt-engineering level — it cannot be bypassed by agent instructions.
- **Audit log:** Every agent action — data query, record modification, escalation — is a Salesforce platform event, written to the org's event log. Security teams can pull a complete interaction audit without accessing conversation content.

**Data level — scoped access:**
- Aria's Einstein Agent User has object-level permissions scoped to `Reservation__c`, `Account` (read), `Contact` (read), and `Case` (create). It cannot access financial records, internal operations objects, or administrative metadata.
- All external callouts (Phase 2 MuleSoft) go through Named Credentials — no API keys or secrets in agent script or Apex code.

**Process level — human escalation gates:**
- Guardrail nodes in Aria's agent script detect topic categories flagged as sensitive: legal disputes, health and safety claims, discrimination allegations, and media inquiries. Any utterance matching these categories triggers an immediate warm transfer to a senior Diner Support agent — the LLM does not attempt to handle them.
- These guardrails are enforced at the platform instruction level (agent script `system:` block and `guardrail` subagent), not at the prompt level. They cannot be overridden by diner input or prompt injection.

---

## Q5: What happens when Aria doesn't know the answer?

**Answer:**

Aria has a three-tier fallback that degrades gracefully without dropping the diner:

**Tier 1 — Einstein Search Grounding on Knowledge.**
Before Aria generates a response to a question it cannot answer from context, it queries the Salesforce Knowledge base via Einstein Search Grounding. Knowledge articles cover restaurant policies, FAQ, dietary accommodation procedures, and group booking rules. If a relevant article exists, Aria cites it and summarizes it. This handles the majority of "I don't know" scenarios without escalation.

**Tier 2 — Omni-Channel warm transfer with transcript.**
If grounding returns no useful result and the query is within scope (booking-related, account-related, or policy-related), Aria transfers the diner to the Diner Support queue via Omni-Channel. The transfer is warm: the accepting agent receives the full conversation transcript and a pre-populated Case record with `Subject`, `Description`, and a lookup to the relevant `Reservation__c`. The diner does not repeat themselves.

**Tier 3 — Case creation for after-hours or no-agent-available scenarios.**
If no live agent is available (outside business hours, queue at capacity), Aria creates a `Case` with `Priority = High`, links it to the diner's `Contact` and `Reservation__c`, and sets `Origin = Chat`. The Case is auto-routed to the Diner Support queue with an SLA clock running. Aria confirms to the diner that their request is logged, provides the Case number, and states the expected response time. Auto-routing fires on next business hour queue processing.

There is no silent failure path. Every conversation that Aria cannot fully resolve either reaches a live agent or creates an auditable Case.

---

## Q6: How does authentication work — can a diner impersonate another diner?

**Answer:**

No. The authentication chain is server-side and cannot be influenced by diner message content.

**How it works:**

1. The diner logs into the Experience Cloud site using their credential (email + password or SSO). Salesforce authenticates them and establishes an EC session with a verified `ContactId`.

2. When the diner opens the Embedded Messaging widget, the EC site's server-side JavaScript passes the authenticated `ContactId` to the Embedded Messaging session as a pre-chat context variable — this is a server-to-server handoff, not user input.

3. Aria's agent script maps this context variable to its `ContactId` session variable via the platform's context variable mapping Flow. This Flow is triggered by the session initialization, not by any diner utterance.

4. The `IsAuthenticated__c` context flag is set to `true` by this platform Flow — and only by this Flow. There is no path in the agent script that sets `IsAuthenticated__c` based on anything the diner says. A diner claiming "I am John Smith, my ContactId is 003XXXXX" in the chat window has no effect — that text is routed to the LLM as conversational input; it never touches the identity variable.

5. All booking modification actions query `Reservation__c WHERE Contact__r.Id = :ContactId` — the ContactId from the authenticated session variable, not from any user-supplied input.

**Result:** A diner can only view and modify reservations associated with their own verified Contact record. There is no client-side identity trust at any point in the chain.

---

## Q7: What is the Flex Credits model and how does it scale?

**Answer:**

Agentforce uses a consumption-based pricing model called Flex Credits, which differs fundamentally from seat-based SaaS licensing.

**How credits work:**
- 1 Flex Credit = 1 Agentforce conversation (regardless of length or number of turns within that conversation).
- List price: approximately $0.10–$0.25 per conversation at current Salesforce pricing (exact rate depends on contract tier and volume commitments).
- Credits are pooled at the org level — all agents, all channels, all teams draw from the same pool.
- Unused credits do not expire within the fiscal year (annual pool).

**Scaling characteristics:**
- There is no step-function pricing. Going from 1,000 to 10,000 conversations per month scales linearly in credit cost — no tier upgrade, no re-provisioning, no infrastructure change.
- There is no AI infrastructure to manage. Salesforce operates the LLM gateway, trust layer, and model infrastructure. The platform team's only operational concern is monitoring credit consumption against the pool.
- Seasonal demand spikes — a restaurant platform sees volume peaks around holidays, Valentine's Day, restaurant week — do not require capacity planning. The credit pool absorbs spikes automatically.

**Cost predictability:**
- Credit consumption is visible in real time in Salesforce Setup (Usage-Based Entitlements dashboard).
- Alerts can be configured at pool percentage thresholds.
- At 5,000 conversations/month at $0.25 list: $1,250/month in AI cost, fully variable with actual usage.

**Contrast with alternatives:** Custom GPT infrastructure requires token-level cost management across model API calls, separate hosting costs, and operational overhead. Per-seat chatbot licensing charges for licensed users whether or not they generate conversations. Flex Credits charge only for value delivered.
