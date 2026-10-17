# Knowledge & Polish Tasks (Adam)

## TASK-A1 (AI drafts, Adam reviews)
Launch general-purpose agent:
> Draft and deploy 5 Salesforce Knowledge articles to FdeCap org using sf CLI. All articles: IsVisibleInCsp=true (visible in Experience Cloud), tagged for Einstein Search Grounding.
>
> Articles to create:
> 1. **Cancellation Policy** — standard 24-hour cancellation window, same-day fee policy, exceptions for weather/emergencies, how to cancel via Aria or the portal
> 2. **How to Modify a Reservation** — step-by-step guide, what can be changed (date, time, party size), modification limits, confirmation email details
> 3. **Restaurant Accessibility Information** — wheelchair access policy, how to request accommodations, what to expect when you arrive, contact for special needs
> 4. **Booking FAQ** — group booking limits, waitlist process, deposit requirements, booking confirmation, re-booking after cancellation
> 5. **Platform Terms Summary** — account creation, data privacy, payment handling, dispute resolution, age restrictions
>
> Use `sf data create record --sobject Knowledge__kav` for each article. Set: Title, Summary (1-2 sentences), Body (plain language, 200-400 words), ArticleType=FAQ__kav, IsVisibleInCsp=true. Publish each article after creation.
>
> After completion, send Slack notification to channel C0C82MYADGW tagging <@U01G1BKBBN2> (Adam Barr) and mark `Ready for Review`.
>
> No permission set changes required — Knowledge is accessible via `Aria_Agent_Access` (Read on Knowledge__kav already granted in TASK-D1). Update TASK-A1 record: `Status__c='Ready for Review'`, `Notes__c='5 Knowledge articles drafted and published. Einstein Search Grounding tags applied. Awaiting Adam review.'`

## TASK-A2 (AI drafts, Adam reviews)
Launch general-purpose agent:
> Read the FDE Capstone build brief at `.claude/docs/build-plan.md`. Draft the following and save to `.claude/docs/adam-review-draft.md`:
>
> 1. **CTO Q&A responses** for:
>    - "Why Agentforce over a cheaper chatbot?" (address: native Salesforce data access, Einstein Trust Layer, no-code customization, CRM integration, Data Cloud grounding, ROI from reduced handle time)
>    - "What is the ROI timeline?" (address: industry benchmarks — 40-60% deflection rate, average $8-12/ticket saved, expected payback period 6-9 months, Flex Credits model)
>    - "What happens when Aria gets it wrong?" (address: escalation paths, Case creation, human handoff, audit trail, continuous improvement via session traces)
>
> 2. **Rubric gap analysis** against the 6 capstone evaluation areas: (a) Agentforce configuration depth, (b) Data model correctness, (c) Integration pattern, (d) Testing coverage, (e) Demo polish, (f) Business case strength. For each area, score current build Level 1–4, identify gaps to reach Level 3+.
>
> 3. **Slide copy fixes** for any Level 1–2 areas found in the gap analysis — suggest revised copy that demonstrates Level 3 thinking.
>
> After completion, send Slack notification to channel C0C82MYADGW tagging <@U01G1BKBBN2> (Adam Barr) and mark `Ready for Review`.
> Update TASK-A2 record: `Status__c='Ready for Review'`, `Notes__c='CTO Q&A + rubric gap analysis drafted. Saved to .claude/docs/adam-review-draft.md. Awaiting Adam review.'`
