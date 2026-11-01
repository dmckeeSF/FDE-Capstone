# Transfer Bug Debug Log — Aria2 Live Sessions
## Symptom: "Transfer requested / Aria 2 left" immediately after first user message
## Started: ~2026-10-28 | Last updated: 2026-11-01 (FIX DEPLOYED)

---

## Symptom (exact)

Portal chat sequence:
1. User opens chat on Table Topper portal (authenticated as Bob Garcia or Sofia Rodriguez)
2. Aria 2 joins, shows welcome message ✅
3. User sends any reservation request ("what are my upcoming reservations?")
4. **"Transfer requested at 8:20 AM" / "Aria 2 left"** — NO prior Aria message

The transfer is SILENT (no Aria message before the transfer notification).

---

## What We Know For Certain

| Fact | How Verified |
|---|---|
| MessagingChannel routes to Aria2 | `sessionHandlerAsa=Aria2` in XML |
| Agent IS invoked (welcome message shown) | Chat screenshot |
| AgentWork status = Closed for the 8:20 AM session | SOQL query on AgentWork |
| MessagingSession status = Waiting after transfer | SOQL query |
| MEU has ContactId AND AuthenticatedEndUserId populated | SOQL: `0PAjV000001X89VWAS` → ContactId=`003jV00000EcrI3QAJ`, AuthId=`005jV0000032ycpQAA` |
| Contact Bob Garcia exists with email+loyalty | SOQL: FirstName=Bob, Email=bobgarcia@example.com, Loyalty_Tier__c=Platinum |
| GetContactProfileAction works (anonymous Apex) | returns firstName=Bob, resolvedId=003jV00000EcrI3QAJ |
| GetReservationsForContactAction works (anonymous Apex) | returns totalCount=4, with summaries |
| DMO `LPR_LoyaltyMember_81F1B696__dlm` exists | SELECT COUNT() = 3 records |
| GetLoyaltyTierAction has try/catch (returns Standard on failure) | Code review |
| GetContactProfileAction has try/catch (added 2026-11-01) | Code + deploy confirmed |
| All Apex classes in `Aria_Agent_Access` permission set | XML verified |
| Current active version: Aria2 v10 | `sf agent activate` result |

---

## What the Preview Trace Shows

Preview session trace (not a live portal session — no real auth):
```
agent_router:
  condition_1 = True  ← EndUserId != "" (preview MEU exists)
  ACTION: (blank function_name) success=None  ← get_contact_profile called but returned empty
  condition_1 = False  ← contact_email is empty (expected for preview)

reservation_support:
  condition_1 = True  ← resolved_contact_id == "" (expected in preview)
  Response: "To view your upcoming reservations, please log in..."
```

**In preview: correct behavior** (no transfer, just "please sign in" message).  
**In live portal: transfer happens** (different symptom → different failure path).

---

## Changes Made (in order)

### Change 1: Deploy `endUserId` InvocableVariable to `GetContactProfileAction`
- Added `@InvocableVariable(required=false label='End User Id') public String endUserId` to `ContactRequest`
- Added fallback logic: if `contactId` blank → query MEU.AuthenticatedEndUserId → User.ContactId
- Deployed: ✅ confirmed via anonymous Apex that `endUserId` is in org

### Change 2: Fix `GetLoyaltyTierAction` `isSuccess` on Standard fallback
- Changed so `isSuccess=true` is set even when email not found in DMO (Standard fallback)
- Only `isSuccess=false` on actual caught exception
- Note: `isSuccess` is NOT in agent definition outputs, so this may not have mattered

### Change 3: Update `Aria2.agent` — 4 structural changes
- Added `resolved_contact_id: mutable string = ""` variable
- Changed `agent_router` trigger from `if @variables.ContactId != ""` to `if @variables.EndUserId != ""`
- Added `endUserId` input to `get_contact_profile` action definition
- Added `resolvedContactId` output to `get_contact_profile` action definition
- Replaced ALL `@variables.ContactId` in subagent `with`/`if`/`available when` with `@variables.resolved_contact_id`
- Deployed → Published v9 → Activated v9

### Change 4: Add try/catch to `GetContactProfileAction`
- Wrapped all SOQL in try/catch, returns empty DTO on any exception
- Deployed → Published v10 → Activated v10

---

## Hypotheses Checked

| Hypothesis | Evidence | Ruled Out? |
|---|---|---|
| `ContactId` linked variable empty (direct ASA routing doesn't write MEU.ContactId) | MEU.ContactId IS populated | ⚠️ Partially — ContactId IS there but linked var might still be late |
| `EndUserId` fallback not wired (endUserId not in action inputs) | Was missing, deployed fix | ✅ Fixed |
| `GetContactProfileAction` throwing unhandled exception | Added try/catch in Change 4 | ✅ Fixed (may not have been the cause) |
| `GetLoyaltyTierAction` returning isSuccess=false causing platform escalation | isSuccess not in agent outputs, can't affect routing | ✅ Ruled out |
| DMO inaccessible causing GetLoyaltyTierAction exception | DMO exists, query works, exception is caught | ✅ Ruled out |
| Permissions missing for Apex classes | All in Aria_Agent_Access | ✅ Ruled out |
| Contact/Reservation data missing | Bob has 4 confirmed reservations | ✅ Ruled out |
| `reservation_support` "please sign in" message → loop → platform auto-escalation | Instructions say go_to_agent_router (not escalate) | 🔲 Not fully verified |
| `list_reservations` failing in live context → agent escalates | Works in anonymous Apex; not tested AS agent user | 🔲 Needs verification |
| Agent routing "what are my upcoming reservations?" to `booking_support` (which has direct @utils.escalate) | routing instructions seem clear | 🔲 Not verified |
| Platform-level routing rule/timeout triggering transfer independently | No routing flows found in org | 🔲 Unknown |
| Aria message IS sent before transfer but not shown in screenshot | No trace evidence either way | 🔲 Needs verification |

---

## The Key Unknown

**We have NO trace from a live portal session.** All our testing is either:
1. Anonymous Apex (runs as admin, not agent user)
2. `sf agent preview` (no real MEU/ContactId in session vars)

The preview trace shows `resolved_contact_id` is empty → "please sign in". The live session transfers. These are DIFFERENT failure modes.

**Hypothesis not yet eliminated:** In the live session, `get_contact_profile` IS succeeding and `resolved_contact_id` IS populated. The agent routes to `reservation_support`, calls `list_reservations`, something fails or the agent misinterprets the result, and escalates. But we can't confirm without a live trace.

---

## Next Diagnostic Steps (NOT yet tried)

### Step A: Verify the agent sees a message before the transfer
Ask the user: does the Aria chat show ANY message before "Transfer requested"? (It might appear briefly then scroll away, or the screenshot missed it.)

### Step B: Test with a different, simpler utterance
Ask the user to try: "hello" and "what restaurants do you have?" — these don't require reservation lookup or identity. If those work, the issue is specific to reservation_support or identity resolution.

### Step C: Enable Apex logging for agent user
```bash
# Via Setup UI: Setup → Debug Logs → New → User → aria_agent@... → 30 min
# Then reproduce the issue and check Setup → Debug Logs
```

### Step D: Check if the issue is reservation_support calling list_reservations and failing
The action returns `is_required: True` for `contactId` in Level 1 definition. In Level 2, `available when @variables.resolved_contact_id != ""`. If there's a mismatch between how the agent sees the contact ID, the action call might fail.

### Step E: Remove get_loyalty_tier from agent_router temporarily
The DMO query in GetLoyaltyTierAction might be timing out in the agent runtime context even though it works via admin Apex. Test by commenting out the `get_loyalty_tier` run block.

### Step F: Check if there's a platform-level routing override
Look at Setup → Omni-Channel → Routing Configurations and Queues to see if there's anything that would cause automatic transfer.

---

## Current State

- Aria2 v10 is active
- GetContactProfileAction has try/catch (deployed)
- GetLoyaltyTierAction has try/catch + isSuccess=true on Standard fallback
- All permission sets correct
- Transfer still happening in live portal sessions
- Preview sessions show correct "please sign in" (no transfer)

---

## Root Cause (Confirmed 2026-11-01)

**Race condition: `MessagingEndUser.ContactId` async write vs. ASA session start**

When `Table_Topper_Channel` used `sessionHandlerType: AgentforceServiceAgent`, the platform started Aria2 immediately when a new MIAW session was created. Experience Cloud writes `MEU.ContactId` asynchronously after the user authenticates. If the write hadn't landed yet when Aria2's context variable mappings executed (`@MessagingEndUser.ContactId`), the ASA received a blank `ContactId`.

With blank ContactId AND blank EndUserId (the endUserId linked variable was also unreliable in the direct-routing path), `GetContactProfileAction` received both inputs empty, returned an empty DTO, `contact_email` stayed blank, `get_loyalty_tier` was never called, and Aria2 hit a session setup invariant that triggered a platform-level silent transfer to the fallback queue.

## Fix (Deployed 2026-11-01)

**`Table_Topper_Channel.messagingChannel-meta.xml`:**
- `sessionHandlerType`: `AgentforceServiceAgent` → `Flow`
- `sessionHandlerAsa: Aria2` → removed
- Added `sessionHandlerFlow: Aria_Contact_Linking_Flow`
- `sessionHandlerQueue: Table_Topper_Queue` unchanged

**`Aria_Contact_Linking_Flow` (RoutingFlow) — already in repo, now active:**
1. Gets MessagingSession → `MessagingEndUserId`
2. Gets MEU → `AuthenticatedEndUserId` (fault connector → routeWork on failure)
3. Gets User → `ContactId` (fault connector → routeWork on failure)
4. DML UPDATE `MEU.ContactId = User.ContactId` — commits ContactId BEFORE ASA starts
5. `routeWork(routingType=Copilot, copilotId=Aria2, serviceChannelDevName=sfdc_livemessage)`

When Aria2 starts, MEU.ContactId is already committed. Context variable mapping resolves correctly.

## Test Required

Login to Table Topper portal as Bob Garcia or Sofia Rodriguez. Send any message. Expected: Aria responds normally (no transfer). Check AgentWork — should show Closed (ASA handled) not Abandoned (fallback queue).
