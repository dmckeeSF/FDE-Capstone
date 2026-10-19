# Rubric Gap Analysis — Aria Capstone Demo

Target: Level 3+ across all 6 rubric areas. Status as of TASK-A2 completion.

---

## 1. Business Problem Definition

**What we have:**
- Clear hospitality use case: diner self-service for booking modification, cancellation, restaurant information, and escalation — all documented in the build plan and agent spec.
- Quantified KPIs defined: deflection rate target (60–70% of tier-1 queries), CSAT improvement target, average handling time reduction.
- Business context established: online hospitality platform, multi-restaurant, authenticated diner population.

**Gap:**
The demo script does not currently open with the business problem statement. If the first 60 seconds of the presentation show the Salesforce UI or the agent conversation, the panel evaluates the technology before understanding why it exists. The demo script must be restructured so the presenter states the business problem — support cost, 24/7 diner expectations, inconsistent policy application — before anything appears on screen.

**Action required:** Destiny or Adam to add a 45-60 second opening monologue to the demo script that anchors the presentation in the business problem. The first slide or screen should show the KPIs, not the agent interface.

---

## 2. Solution Architecture

**What we have:**
- Full Agentforce ASA stack deployed: Aria agent script, 5 topics, action implementations.
- Named Credentials for all external callouts (no hardcoded secrets).
- Experience Cloud site with authenticated diner sessions and Embedded Messaging.
- Omni-Channel warm transfer to Diner Support queue.
- Salesforce Knowledge with Einstein Search Grounding.
- Data Cloud Phase 1 planned (read-only grounding, not yet built — correctly scoped to Phase 2 proactive re-booking).
- Einstein Trust Layer active (zero data retention, PII masking).

**Gap:**
There is no architecture diagram with data flow arrows. A component list (even a complete one) does not satisfy Level 3+ on architecture — evaluators need to see the data flow: diner browser → EC session → Embedded Messaging → Agentforce runtime → Trust Layer → LLM → Apex actions → Reservation__c → response. The diagram should show where authentication happens, where PII masking occurs, and where the Omni-Channel handoff point is.

**Action required:** Create one architecture diagram (Lucidchart, Miro, or PowerPoint) showing component relationships with labeled data flow arrows. The diagram should be readable at presentation resolution. This is a blocking gap for Level 3 on this rubric area.

---

## 3. Agent Design

**What we have:**
- 5 topics: Booking Management, Restaurant Info, Platform FAQ, Escalation, Guardrails.
- Authentication context variables mapped from Experience Cloud session (server-side, not user-claimed).
- Slot-filling for modification requests (date, party size, special requests).
- Guardrail nodes enforced at the platform level for sensitive topic categories.
- Escalation triggers with Omni-Channel warm transfer and Case creation fallback.
- `IsAuthenticated__c` flag set only by platform Flow, not by diner input.

**Gap:**
The planned demo conversation is single-turn per topic (one modification, then done). Evaluators assessing agent design quality want to see context retention across turns: a diner modifies a reservation, then asks a follow-up question about the restaurant's cancellation policy in the same session, and Aria correctly maintains the reservation context without asking the diner to repeat themselves. This demonstrates that the agent retains slot state across subagent transitions — a key differentiator from stateless chatbots.

**Action required:** Add a multi-turn demo path to the demo script: (1) diner requests modification, (2) Aria completes modification, (3) diner asks "what is the cancellation policy for this restaurant?", (4) Aria answers using the Knowledge article grounded on the correct restaurant Account. Rehearse this path specifically — multi-turn flows are more likely to surface unexpected behavior during live demos.

---

## 4. Integration

**What we have:**
- Named Credential + Apex REST mock API: GET (read reservation), PATCH (modify), DELETE (cancel) on `Reservation__c`.
- Flow-invocable Apex actions wired to agent script actions for all booking operations.
- Experience Cloud authenticated session passing `ContactId` server-side to Embedded Messaging.
- Architecture is production-ready: the mock Apex layer is a Named Credential target, not hardcoded logic — swapping in a MuleSoft endpoint requires only a Named Credential URL update.

**Gap:**
The integration story needs to be verbalized during the demo, not just implied by the working demo. Evaluators may not recognize that the Named Credential + mock pattern is intentional production scaffolding. If the presenter doesn't say "the Apex mock simulates a MuleSoft integration — replacing it in production requires only a Named Credential update, no agent or Flow changes," the evaluator may score this as a prototype limitation rather than an architectural decision.

**Action required:** Add one sentence to the demo script at the point where a booking modification is executed: explain that the call goes through a Named Credential, the Apex mock is a stand-in for MuleSoft, and the production path is identical in architecture. No code changes needed — this is a presentation gap, not a build gap.

---

## 5. Testing and Quality

**What we have:**
- Apex test classes deployed with 90%+ coverage requirement enforced.
- Test categories planned in TASK-T1: functional (happy path per subagent), edge (boundary inputs), multi-turn (context retention across turns), perturbation (paraphrase variations of key utterances), adversarial (prompt injection, identity spoofing, out-of-scope requests).
- Flow fault paths implemented on all invocable action flows.

**Gap:**
TASK-T1 has not been executed yet. The rubric requires evidence of testing results, not just a testing plan. If the demo includes a "testing and quality" slide that shows only the test categories without pass/fail results, it will not satisfy Level 3. The slide needs actual test run output: number of test cases per category, pass rate, and which failures were remediated.

**Action required:** TASK-T1 must be completed before the demo. The test results output (pass/fail by category, total pass rate, any failures with remediation notes) should be captured and added to the presentation slide. This is a time-dependent gap — block time for TASK-T1 execution at least 48 hours before the demo to allow for fix cycles.

---

## 6. Presentation and Demo

**What we have:**
- Sofia Rodriguez demo user configured on the Experience Cloud site with a live `Contact` record and associated `Reservation__c` records.
- Full booking modification + FAQ + escalation flow tested in preview.
- Experience Cloud site live and accessible at the demo URL.
- Warm transfer configured to Diner Support Omni-Channel queue.

**Gap:**
The warm transfer moment — the most architecturally distinctive part of the demo — has not been rehearsed to completion. The panel will want to see: (1) Aria detecting an escalation trigger, (2) the warm transfer initiating, (3) the Case created with the conversation transcript attached, (4) the Diner Support agent view showing the pre-populated Case. Steps 3 and 4 are likely to have rough edges under demo conditions (Case creation timing, queue routing, agent console layout). If the presenter cannot walk through these steps fluently, the integration story loses credibility.

**Action required:** Rehearse the complete warm transfer moment end-to-end at least twice, including the agent console view. Confirm that Case creation is fast enough to show in real time (typically sub-3 seconds). Prepare a fallback screenshot of the Case record with transcript attached in case live demo timing is unpredictable. Assign this rehearsal to Destiny and confirm with Adam before final demo prep.

---

## Summary Table

| Rubric Area | Current Status | Gap Severity | Blocking? |
|---|---|---|---|
| Business Problem Definition | Strong content, weak opening | Medium | No — fix in demo script |
| Solution Architecture | Complete stack, no diagram | High | Yes — diagram required for L3 |
| Agent Design | Complete, single-turn demo | Medium | No — add multi-turn path |
| Integration | Production-ready, not verbalized | Low | No — one sentence in script |
| Testing and Quality | Plan exists, no results | High | Yes — run TASK-T1 first |
| Presentation and Demo | Live but unrehearsed escalation | High | Yes — rehearse warm transfer |

**Critical path before demo:** Architecture diagram + TASK-T1 execution + warm transfer rehearsal.
