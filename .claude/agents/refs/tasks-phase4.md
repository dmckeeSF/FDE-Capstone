# Phase 4 — Channels & Surface Tasks

## TASK-D11
Launch `adlc-engineer`:
> Create Experience Cloud site in FdeCap using Customer Service template. Site name: Aria Dining Portal. Configure:
> - Authenticated access for Contact-based Community users (Diner profile)
> - Guest User Profile: Read on Account (Restaurant Record Type) and Knowledge articles only
> - Embed Agentforce chat widget on booking confirmation page, targeting Aria agent
> - Public pages: restaurant directory (Account RT: Restaurant), knowledge base search
> - Authenticated pages: booking history, reservation management
> Deploy and publish the site. Report the site URL.

### Permission Set Steps (TASK-D11)
After Experience Cloud site is deployed and published:
1. Configure the **Guest User Profile** via Setup (cannot deploy via metadata for EC guest profiles — must be done in Setup UI or via permission set on the site):
   - Read on Account (Record Type: Restaurant)
   - Read on Knowledge articles
   - No access to Contact, Reservation__c, Case
2. Create permission set `Diner_Community_Access` for authenticated diner users:
   - Read + Edit on `Reservation__c` (own records only — enforce sharing)
   - Read on Account (Restaurant RT)
   - Read on Knowledge
   - No access to Build_Task__c, Case, or other internal objects
   ```bash
   # Deploy Diner_Community_Access permission set metadata, then assign to Community profile
   sf project deploy start --metadata "PermissionSet:Diner_Community_Access" --target-org FdeCap
   ```
3. Update TASK-D11 record:
   ```bash
   sf data update record --sobject Build_Task__c --where "Name='TASK-D11'" \
     --values "Notes__c='Experience Cloud site deployed. Guest User Profile configured. Diner_Community_Access PS created. Site URL: <url>' Status__c='Done'" \
     --target-org FdeCap
   ```

## TASK-D12 (Omni-Channel with auto Slack fallback)
Launch `adlc-engineer`:
> Attempt to configure Omni-Channel in FdeCap in this order:
>
> Step 1 — Omni-Channel: Enable Omni-Channel, create Service Channel for Messaging, create Queue "Diner Support", create Routing Configuration (routing model: Least Active), enable Presence Status "Available for Diners", add to Service Console app, add team members (dmckee@fdecapstone.com.161026, abarr@fdecapstone.com.161026, zcopman@fdecapstone.com.161026) as queue members.
>
> Step 2 — If any Step 1 deployment fails: automatically fall back to Slack escalation flow instead. Create an Autolaunched Flow named "EscalationToSlack" triggered when a Case with Issue_Classification__c is created from Aria. Flow posts to Slack channel C0C82MYADGW with: diner name, Reservation__c link, conversation transcript (Conversation_Transcript__c), recommended next action.
>
> Report which path was taken (Omni-Channel or Slack fallback) and what was deployed.

### Permission Set Steps (TASK-D12)
**If Omni-Channel path was taken:**
1. Assign Service Presence permission to all three team members so they can go Available and receive warm transfers:
   ```bash
   # Query for the Service Presence permission set dynamically (standard PS name varies by org)
   PRESENCE_PS=$(sf data query \
     --query "SELECT Name FROM PermissionSet WHERE Name LIKE '%ServicePresence%' OR Name LIKE '%OmniChannel%' LIMIT 1" \
     --target-org FdeCap --json | jq -r '.result.records[0].Name // empty')
   for USER in dmckee@fdecapstone.com.161026 abarr@fdecapstone.com.161026 zcopman@fdecapstone.com.161026; do
     sf org assign permset --name "$PRESENCE_PS" --on-behalf-of "$USER" --target-org FdeCap
   done
   ```
2. If the query returns empty (no standard PS exists), create a minimal `Diner_Support_Presence` permission set with `ServicePresence` system permission enabled.

**If Slack fallback path was taken:**
No permission set changes needed — Slack posts via Flow using org credentials.

Update TASK-D12 record:
```bash
sf data update record --sobject Build_Task__c --where "Name='TASK-D12'" \
  --values "Notes__c='Omni-Channel OR Slack fallback deployed. Service Presence PS assigned to Destiny/Adam/Zach.' Status__c='Done'" \
  --target-org FdeCap
```

## TASK-D14
Depends on: TASK-D11 (Experience Cloud live) + TASK-Z1 (Sofia Rodriguez Contact record exists).

Launch `adlc-engineer`:
> Create Experience Cloud Community User for Sofia Rodriguez in FdeCap. Use dynamic queries — no hardcoded IDs:
>
> ```bash
> PROFILE_ID=$(sf data query --query "SELECT Id FROM Profile WHERE Name='Customer Community User'" --target-org FdeCap --json | jq -r '.result.records[0].Id')
> CONTACT_ID=$(sf data query --query "SELECT Id FROM Contact WHERE Email='sofiarodriguez@example.com'" --target-org FdeCap --json | jq -r '.result.records[0].Id')
> sf data create record --sobject User \
>   --values "FirstName='Sofia' LastName='Rodriguez' Username='sofiarodriguez@fdecapstone.com.demo' Email='sofiarodriguez@example.com' Alias='srodrig' CommunityNickname='sofia_diner' ProfileId='$PROFILE_ID' ContactId='$CONTACT_ID' TimeZoneSidKey='America/Los_Angeles' LocaleSidKey='en_US' EmailEncodingKey='UTF-8' LanguageLocaleKey='en_US' IsActive=true" \
>   --target-org FdeCap
> ```
>
> Verify the user can log in to the Experience Cloud site. Report the Community User Id.

On completion, update TASK-D14 record: `Status__c='Done'`, `Notes__c='Sofia Rodriguez community user created. Username: sofiarodriguez@fdecapstone.com.demo. Profile: Customer Community User.'`
