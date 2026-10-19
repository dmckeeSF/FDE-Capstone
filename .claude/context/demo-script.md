# Aria Demo Script
**FDE Capstone | Team 4 | Intelligent Diner Support Agent**

---

## Opening (45 seconds — before touching the screen)

> "Online hospitality platforms face a consistent support problem: most tier-1 inquiries — 'can I move my reservation?', 'what's the cancellation policy?', 'is there a window table?' — are handled by human agents at significant cost, with inconsistent answers and no 24/7 coverage.
>
> Our platform serves thousands of diners across multiple restaurants. We built Aria — an Agentforce Autonomous Service Agent — to handle that tier-1 volume. Tonight we'll show you three things: a live reservation modification, a knowledge-grounded FAQ response, and a warm transfer to a human agent. Everything you see is running live in our Salesforce org."

*[Show the KPI slide: 60–70% deflection target, CSAT improvement, AHT reduction]*

---

## Scene 1 — Diner Login + Greeting (1 minute)

> "Bob Garcia is a Gold tier diner. He's logged into our Experience Cloud site to manage his upcoming reservation at The Golden Fork."

1. Open the Experience Cloud site as Bob Garcia
2. Navigate to the booking confirmation page for his reservation at The Golden Fork
3. The Aria chat widget appears automatically

**Bob types:** `Hi there`

**Expected:** Aria greets — *"Hi! I'm Aria, your dining assistant. I can help you modify or cancel a reservation, look up restaurant details, or answer questions about your booking. How can I help?"*

---

## Scene 2 — Reservation Modification (2 minutes)

> "Bob needs to move his dinner from November 8th to November 15th — his plans changed."

**Bob types:** `I need to change my reservation date`

**Expected:** Aria routes to reservation_support, identifies Bob's booking reference from session context, retrieves current reservation details.

**Bob types:** `November 15th`

**Expected:** Aria confirms — *"I can move your reservation at The Golden Fork from November 8th to November 15th for 2 guests. Shall I go ahead?"*

**Bob types:** `Yes please`

**Expected:** Aria calls ModifyReservationAction, confirms — *"Done! Your reservation at The Golden Fork has been updated to November 15th at 7:00 PM for 2 guests. You'll receive a confirmation email shortly."*

> *[Presenter: "The modification went through a Named Credential to our Apex integration layer — the same architecture that would call MuleSoft in production. Swapping to a live endpoint requires only a Named Credential URL change — no agent or Flow modifications."]*

---

## Scene 3 — Follow-up FAQ (1 minute — context retention)

> "Bob has a follow-up question — without re-identifying himself or restarting the conversation."

**Bob types:** `What's the cancellation policy if I need to cancel later?`

**Expected:** Aria routes to platform_faq, calls SearchKnowledgeAction, returns policy — *"Cancellations are free up to 24 hours before your reservation. Same-day cancellations may incur a fee. As a Gold tier member, you're protected under our standard policy."*

> *[Presenter: "Aria retained context across topic transitions — it knew we were still talking about Bob's booking without him having to repeat himself. This is the return-to-router pattern in our agent design."]*

---

## Scene 4 — Escalation + Warm Transfer (1.5 minutes)

> "Bob decides he'd rather speak to someone directly."

**Bob types:** `Actually, I'd like to talk to a real person`

**Expected:** Aria routes to escalation — *"Of course — let me connect you to a member of our support team now. Please hold for a moment."*

**Expected:** Omni-Channel warm transfer fires → human agent console shows Bob's case with conversation transcript pre-populated.

*[Switch to agent console view]*

> *[Presenter: "The support agent receives the full conversation transcript, Bob's reservation details, and his loyalty tier — no repeat of context. This is the Omni-Channel warm transfer with the Einstein Trust Layer ensuring PII handling throughout."]*

---

## Closing (30 seconds)

> "What you've seen is running on Agentforce ASA with Experience Cloud authentication, Salesforce Knowledge, Omni-Channel, and the Einstein Trust Layer — zero data retention, PII masking throughout. Phase 2 expands this to proactive re-booking via Data Cloud activation when a restaurant cancels. Thank you."

---

## Demo Checklist (run through before presenting)

- [ ] Bob Garcia logged in to Experience Cloud site
- [ ] Bob's Golden Fork reservation (Nov 8) visible on booking page
- [ ] Aria chat widget loads on booking confirmation page
- [ ] Nov 15 is available at The Golden Fork (check availability)
- [ ] Human agent (Adam or Zach) logged in to Service Console and set to Available
- [ ] Omni-Channel routing confirmed to Diner Support queue
- [ ] Fallback: Case creation screenshot ready if live transfer has latency

## Demo User

| Field | Value |
|---|---|
| Name | Bob Garcia |
| Membership Number | 10008165 |
| Loyalty Tier | Gold |
| Email | bobgarcia@example.com |
| Key Reservation | The Golden Fork, Nov 8 2026, 7:00 PM, 2 guests |
| Booking Reference | Auto-assigned (RES-000021+) |
