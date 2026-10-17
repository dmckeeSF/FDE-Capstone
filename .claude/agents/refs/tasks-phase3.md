# Phase 3 — Agentforce Build Tasks

## TASK-D5
Launch `adlc-author`:
> Create Agentforce agent in FdeCap: Name=Aria, Type=ASA Live, Einstein Trust Layer enabled (zero data retention, PII masking on).
> Opening message: "Hi! I'm Aria, your dining assistant. I can help you modify or cancel a reservation, look up restaurant details, or answer questions about your booking. How can I help?"
> Assign Permission Set Aria_Agent_Access.
>
> Create the Omni-Channel Flow for context variable mapping: fires on MessagingSession creation, reads the authenticated Experience Cloud Contact using the session ContactId, maps to MessagingSession custom fields: ContactId__c, MembershipNumber__c (from Contact.Membership_Number__c), IsAuthenticated__c=true if Contact found, LoyaltyTier__c from Contact.Loyalty_Tier__c, BookingReference__c from URL parameter if present.

### Permission Set Steps (TASK-D5)
After agent and Omni-Channel Flow deploy:

> **Platform architecture — Dedicated Agent Service Account:**
>
> The correct pattern is a **dedicated Einstein Agent User service account**, not a human user and not the auto-provisioned bot user.
>
> **Step 1 — Create the service account via Apex (not metadata — LicenseId must be null):**
> ```apex
> String orgId = UserInfo.getOrganizationId().left(15).toLowerCase();
> String username = 'aria_agent@' + orgId + '.ext';
> Profile p = [SELECT Id FROM Profile WHERE Name = 'Einstein Agent User' LIMIT 1];
> insert new User(FirstName='Aria', LastName='Agent', Email='aria_agent@fdecapstone.com',
>     Username=username, Alias='aria', TimeZoneSidKey='America/Los_Angeles',
>     LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US',
>     ProfileId=p.Id, IsActive=true);
> ```
>
> **Step 2 — Assign system PS:**
> ```bash
> sf org assign permset --name AgentforceServiceAgentUser --on-behalf-of aria_agent@<orgId>.ext --target-org FdeCap
> ```
>
> **Step 3 — Aria_Agent_Access must have NO license restriction (LicenseId = null).**
> The metadata API always defaults PSs to the Salesforce UserLicense. To avoid this, create/recreate `Aria_Agent_Access` via Apex DML with no `LicenseId` field set — do NOT deploy it via `sf project deploy` after this point or the license will be reset. See the recreation script in `/tmp/recreate_aria_ps.apex`.
>
> **Step 4 — Assign Aria_Agent_Access to service account via CLI (works once PS is license-agnostic):**
> ```bash
> sf org assign permset --name Aria_Agent_Access --on-behalf-of aria_agent@<orgId>.ext --target-org FdeCap
> ```
>
> **Step 5 — Set `default_agent_user` in `Aria.agent`:**
> ```yaml
> config:
>     default_agent_user: "aria_agent@<orgId>.ext"
> ```

1. Ensure `Aria_Agent_Access` includes Read+Edit on `MessagingSession` (already in the PS from TASK-D1). Verify:
   ```bash
   sf data query --query "SELECT ObjectType FROM ObjectPermissions WHERE Parent.Name='Aria_Agent_Access' AND SObjectType='MessagingSession'" --target-org FdeCap --json
   ```
2. Update TASK-D5 record:
   ```bash
   sf data update record --sobject Build_Task__c --where "Name='TASK-D5'" \
     --values "Notes__c='Aria agent deployed. Omni-Channel context variable Flow deployed. Running User must be set in Agentforce Studio UI — CLI permset assignment not supported for bot user license.' Status__c='Done'" \
     --target-org FdeCap
   ```

## TASK-D6 — Topic: Booking Management
Launch `adlc-author`:
> Add Booking Management topic to Aria in FdeCap.
>
> Topic filter: Only proceed when {!$Context.IsAuthenticated__c} is true. If false: "Please log in to your account to manage your reservation."
>
> Actions:
> - Get Reservation Details: calls GetReservationAction Flow. Slot: bookingReference (pre-fill from {!$Context.BookingReference__c} if present). Requires authenticated session.
> - Modify Reservation: calls ModifyReservationAction Flow. Slots: bookingReference, newDate, newTime, newPartySize. Confirm with diner before executing. Max 2 clarification turns.
> - Cancel Reservation: calls CancelReservationAction Flow. Slots: bookingReference, cancellationReason. Confirm before executing. Check policy window — if outside window, escalate instead of cancelling.
>
> Pass {!$Context.ContactId__c} to all actions for identity verification. Never ask the diner to identify themselves.

On completion, update TASK-D6 record: `Status__c='Done'`, `Notes__c='Booking Management topic deployed with Get/Modify/Cancel actions. Authentication context variable filter active.'`

## TASK-D7 — Topic: Restaurant Information
Launch `adlc-author`:
> Add Restaurant Information topic to Aria in FdeCap. No authentication filter — accessible to all users.
>
> Actions:
> - Get Restaurant Info: SOQL Agent Action on Account (Record Type: Restaurant). Returns hours, cuisine, policies, accessibility info, dress code.
> - Check Availability: SOQL on Reservation__c COUNT for restaurant + date, returns available slots vs Max_Party_Size__c.

On completion, update TASK-D7 record: `Status__c='Done'`, `Notes__c='Restaurant Information topic deployed with Get Info + Check Availability SOQL actions.'`

## TASK-D8 — Topic: Platform FAQ
Launch `adlc-author`:
> Add Platform FAQ topic to Aria in FdeCap. No authentication filter.
>
> Action: Search Knowledge Base via Einstein Search Grounding.
> Scope: Knowledge articles tagged: Cancellation Policy, Booking FAQ, Accessibility, Restaurant Policies.
> Depends on TASK-A1 (Knowledge articles must be deployed and tagged before this topic works).

On completion, update TASK-D8 record: `Status__c='Done'`, `Notes__c='Platform FAQ topic deployed. Einstein Search Grounding scoped to 4 Knowledge categories.'`

## TASK-D9 — Topic: Escalation + Guardrails
Launch `adlc-author`:
> Add Escalation topic and guardrail nodes to Aria in FdeCap.
>
> Escalation triggers (in priority order):
> 1. No Knowledge answer after search → escalate or create support ticket
> 2. Confidence below threshold after 2 clarification turns → warm transfer + transcript
> 3. Diner says "human", "agent", "talk to someone" → warm transfer
> 4. Cancellation outside policy window → warm transfer + Case
> 5. Payment/billing request → immediate warm transfer
> 6. Emotional distress keywords → immediate warm transfer
> 7. Accessibility accommodation → warm transfer with priority flag
> 8. Legal/safety/discrimination → immediate warm transfer + Case
>
> Fallback when no agent available: create Case (Priority=High, Conversation_Transcript__c populated), notify diner via email, auto-route to queue on next business hour.
>
> Guardrail nodes (configure in Script Builder):
> - Food safety/health complaints → "That's outside what I can help with today, but I can connect you with our support team."
> - Legal/discrimination claims → immediate warm transfer + Case
> - Competitor comparisons → decline and redirect
> - Payment disputes → immediate warm transfer
> - Any request outside hospitality/booking domain → decline

On completion, update TASK-D9 record: `Status__c='Done'`, `Notes__c='Escalation topic + 5 guardrail nodes deployed. All 8 escalation triggers configured.'`
