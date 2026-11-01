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

## Current State (updated 2026-11-01, resumed session)

- Aria2 **v21** active ✅ (v19 was active before resume — v20 bundle was deployed but never published; published + activated as v21 in this session)
- Channel: `sessionHandlerType: Flow`, `sessionHandlerFlow: Aria_Contact_Linking_Flow` ✓
- `connection messaging:` with `outbound_route_name: flow://Aria_Escalation_Flow` + `escalation_message:` ✓
- v21 confirmed: `escalationMessage` + `outboundRouteName: Aria_Escalation_Flow` in deployed XML ✓
- Pushed to `capPriv` ✓
- **TRANSFER BUG FIX PUBLISHED — Awaiting live portal test**

### Root Cause (Final — 2026-11-01, 1:15 PM)
Three separate issues were present:

**Issue 1 (Fixed 12:10 PM):** `sessionHandlerType: AgentforceServiceAgent` bypassed the Omni-Channel Flow, leaving `ContactId` permanently null. Fixed by switching to `sessionHandlerType: Flow` + `Aria_Contact_Linking_Flow`.

**Issue 2 (Fixed 12:45 PM):** `connection messaging:` block was removed, stripping `plannerSurfaces: Messaging` from deployed XML. Agent planner couldn't handle Messaging work → AgentWork closed with ActiveTime=0. Restored `connection messaging:` block.

**Issue 3 (Fixed 1:15 PM — ROOT CAUSE of original transfer bug):** `connection messaging:` block was missing `escalation_message:` field. The Salesforce platform requires this field for Messaging connection type. Without it, the platform cannot initialize the agent's Messaging session → preview fails with "Escalation message is mandatory for connection type Messaging" → AgentWork closes immediately (ActiveTime=0) on EVERY live portal session since v16.

**Evidence:**
- v18 XML: has `plannerSurfaces: Messaging` but NO `outboundRouteConfigs` / no `escalationMessage`
- v16 XML: has `outboundRouteConfigs` with `outboundRouteName: Aria_Escalation_Flow` but no `escalationMessage`
- `sf agent preview start` failed with: `"Escalation message is mandatory for connection type Messaging"`
- v20 XML: has `plannerSurfaces: Messaging` + `outboundRouteName: Aria_Escalation_Flow` + `escalationMessage` ✓
- Preview: session starts, "What restaurants do you have in Seattle?" → routes to `restaurant_info`, returns Pike Place Provisions ✓

## What We've Tried (full history)

| Attempt | Change | Result |
|---|---|---|
| v16 | outbound_route_name → Aria_Escalation_Flow | Still transfers |
| v17 | same as v16 | Still transfers |
| v18 | outbound_route_name → "flow://" (empty) | Still transfers |
| v19 | Remove `connection messaging` block entirely | Still transfers (AND lost plannerSurfaces: Messaging — AgentMessageCount=0 on all sessions) |
| Channel: ASA | sessionHandlerType: AgentforceServiceAgent | Still transfers |
| Channel + ESConfig redeploy | Redeployed both EmbeddedServiceConfig files | Still transfers |
| Channel: Flow | sessionHandlerType: Flow + Aria_Contact_Linking_Flow | MEU.ContactId set ✓, but AgentMessageCount=0 because v19 had no plannerSurfaces |
| v18 re-activated | connection messaging restored (flow://Aria_Escalation_Flow), channel stays Flow | Still AgentWork ActiveTime=0 — missing escalation_message in connection messaging: block |
| **v20** | **Added `escalation_message:` to `connection messaging:` block** | **FIXED ✅ — Preview routes correctly, restaurant_info responds with real data** |

## What We Know For Certain (NEW — 2026-11-01)

| Fact | How Verified |
|---|---|
| EmbeddedServiceConfig has no routing/timeout config | Read both Table_Topper_Channel and Table_Topper_Embedded_Service_Deployment XML files |
| Every session creates 2 AgentWork records: Abandoned (ActiveTime=null) then Closed (ActiveTime=0) | SOQL AgentWork query |
| AgentMessageCount=0 on ALL MessagingSessions | SOQL MessagingSession query |
| EndedByType=EndUser on all ended sessions | SOQL MessagingSession query |
| Portal users are on "Customer Community Plus Login User" profile (PowerCustomerSuccess) | SOQL User query |
| Portal profile has ZERO Apex class accesses at profile level | SetupEntityAccess query |
| Aria_Portal_Access permset is assigned to ALL 12 portal users including Bob and Sofia | PermissionSetAssignment query |
| Aria_Portal_Access permset has all 11 invocable class accesses in XML | File read |
| "Works in preview but not in portal" = "Preview runs as admin; portal runs as portal user" | PDF: Service Agent with Credential-Based User Verification |
| The Omni-Channel Flow is REQUIRED; without it ContactId is never populated | PDF: confirmed by testing, green callout box |

## Root Cause (Revised 2026-11-01, 12:11 PM)

**`sessionHandlerType: AgentforceServiceAgent` bypasses the Omni-Channel Flow, leaving `ContactId` permanently null.**

Per Salesforce testing (PDF: "Service Agent with Credential-Based User Verification on Experience Cloud"):
> "Testing confirmed that without a flow that explicitly establishes the Contact-to-MessagingEndUser association, the ContactId linked variable is never populated — even with credential-based verification enabled on both the channel and deployment. Direct agent routing via the channel (without a flow) does not fill the ContactId."

When ContactId and EndUserId are both null, Aria2 can't resolve identity. With `AgentMessageCount=0` on every live session, the ASA never successfully handles any message — it immediately transfers, creating the Abandoned+Closed AgentWork pair.

The "debug logs not appearing" observation was misleading: Apex runs as the PORTAL USER (not the Einstein Agent User) in authenticated sessions. Debug logs were set up for the wrong user.

The "welcome message" users see is likely a platform-level greeting from the Embedded Service Deployment, not from Aria2's agent script (explaining AgentMessageCount=0).

## Fix (Deployed 2026-11-01, 12:10 PM)

**`Table_Topper_Channel.messagingChannel-meta.xml`:**
- `sessionHandlerType`: `AgentforceServiceAgent` → `Flow`
- `sessionHandlerAsa: Aria2` → removed
- Added `sessionHandlerFlow: Aria_Contact_Linking_Flow`
- `sessionHandlerQueue: Table_Topper_Queue` unchanged

**`Aria_Contact_Linking_Flow` (RoutingFlow):**
1. Gets MessagingSession → MessagingEndUserId
2. Gets MEU → AuthenticatedEndUserId
3. Gets User → ContactId
4. UPDATE MEU.ContactId = User.ContactId (commits ContactId BEFORE ASA starts)
5. routeWork(Copilot, Aria2, Table_Topper_Queue)

## Test Required

Login to Table Topper portal as Bob Garcia or Sofia Rodriguez. Send any message. Expected: Aria responds normally (no transfer). Check `AgentWork` — should show Closed with ActiveTime > 0.

## NOT YET CHECKED

1. `ServiceAgentEscalationFlow` system flow — what triggers it (lower priority now)
2. Whether `Aria_Portal_Access` permset class accesses are live in org (they're in XML + assigned, but worth verifying if test fails)

---

## ARIA 3 — EM2 Pattern (SDO-Style) — Started 2026-11-01

### Decision to Abandon Aria2 / Table Topper Channel Approach

After exhaustive debugging, Aria2 on the Table Topper Channel still transfers on every live portal session. Confirmed root causes investigated and fixed:
- `escalationMessage` missing → fixed (v21)
- `setupReference` for copilotId → fixed (dynamic BotDefinition lookup)
- Einstein Agent User not in Presence Config → fixed (added to Table Topper Presence Config)

Still transferring. The Table Topper channel uses `authMode: Auth` (credential-based JWT verification) which adds complexity the SDO reference implementation does not have. Rather than continue patching, pivot to a clean EM2 pattern matching the SDO exactly.

### Aria 3 Architecture

| Component | Value |
|---|---|
| Agent bundle | `Aria3` — copy of Aria2 agent script |
| Routing flow | `Aria3_Routing_Flow` — simple SDO-style: Get_Queue → Get_Agent → Route_Work(Copilot, Aria3) |
| Messaging channel | `Aria3_Channel` — EmbeddedMessaging, NO `authMode: Auth`, sessionHandlerType: Flow |
| EmbeddedService deployment | `Aria3_Embedded_Service` — new deployment on same site |
| Escalation flow | `Aria3_Escalation_Flow` — routes to Table_Topper_Queue |
| Presence config | Add Aria3's Einstein Agent User to Table_Topper_Presence_Config after first publish |

### Key Differences from Aria2 / Table Topper

1. **No `authMode: Auth`** — removes JWT credential verification; contact linking done via routing flow if MEU has AuthenticatedEndUserId, otherwise graceful fallback
2. **Simplified routing flow** — no complex Contact linking chain that could fail silently
3. **New agent user** — Aria3 gets its own Einstein Agent User on first publish (must add to presence config)
4. **Clean slate** — no legacy Table Topper channel config in the critical path

### Execution Steps

- [x] Step 1: Generate Aria3 authoring bundle — `sf agent generate authoring-bundle --no-spec --api-name Aria3`
- [x] Step 2: Copy Aria2 agent script → Aria3, updated `developer_name: "Aria3"`, `agent_label: "Aria 3"`, `outbound_route_name: "flow://Aria3_Escalation_Flow"`
- [x] Step 3: Created `Aria3_Escalation_Flow` — routes to Table_Topper_Queue via routingType=Queue, deployed (id `301jV00000JKtobQAD`)
- [x] Step 4: Created `Aria3_Routing_Flow` — Get_Queue → Get_Agent (BotDefinition WHERE DeveloperName='Aria3') → Get_Service_Channel → routeWork(Copilot, Aria3), deployed (id `301jV00000JKtocQAD`)
- [x] Step 5: Created `Aria3_Channel` — EmbeddedMessaging, sessionHandlerType: Flow, sessionHandlerFlow: Aria3_Routing_Flow, deployed and Activated (id `0MjjV000000IdnhSAC`)
- [x] Step 6: Created `Aria_3_Embedded_Service` EmbeddedServiceConfig — via UI wizard (Embedded Service Deployments); wizard auto-created CustomSite `ESW_Aria_3_Embedde_17935743398721` and associated Network. Metadata API direct deploy was blocked: ChatterNetwork-type CustomSites require a pre-existing Experience Cloud Network.
- [x] Step 7: Deployed all metadata — flows via `sf project deploy start`, channel via deploy, ESConfig via wizard + retrieve
- [x] Step 8: Validated, published (`sf agent publish authoring-bundle --api-name Aria3` → success: true, deployed: 3), activated (`sf agent activate --api-name Aria3` → Status: 0)
- [x] Step 9: Aria3 reuses same Einstein Agent User (`aria_agent@00djv000005aree.ext`) as Aria2 — no new agent user created on publish. Existing `Table_Topper_Presence_Config` assignment already covers Aria3.
- [ ] Step 10: Update Experience Cloud site to use Aria3_Embedded_Service — PENDING (requires portal page edit in Experience Builder)

### Current Status (2026-11-01)

**Aria 3 is fully deployed and activated in org.** All metadata is retrieved to `force-app/`.

| Component | Status |
|---|---|
| `Aria3_Routing_Flow` | ✅ Deployed, Active |
| `Aria3_Escalation_Flow` | ✅ Deployed, Active |
| `Aria3_Channel` | ✅ Deployed, Active (id `0MjjV000000IdnhSAC`) |
| `Aria_3_Embedded_Service` | ✅ Created via wizard, published |
| `Aria3` AiAuthoringBundle | ✅ Deployed, published, activated |
| Presence Config | ✅ `aria_agent@00djv000005aree.ext` already in Table_Topper_Presence_Config |

**Key discovery:** Raw metadata-deployed MessagingChannels DO appear in the Embedded Service Deployments wizard channel picker (earlier assumption was wrong). The only blocker was the CustomSite dependency — resolved by using the wizard.

**Remaining:** Wire the Aria 3 Embedded Service snippet into the Experience Cloud portal page (Step 10). Until then, Aria 3 is live in the org but not yet surfaced to diners via the portal.

