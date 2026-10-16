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

## TASK-D12 (Omni-Channel with auto Slack fallback)
Launch `adlc-engineer`:
> Attempt to configure Omni-Channel in FdeCap in this order:
>
> Step 1 — Omni-Channel: Enable Omni-Channel, create Service Channel for Messaging, create Queue "Diner Support", create Routing Configuration (routing model: Least Active), enable Presence Status "Available for Diners", add to Service Console app, add team members (dmckee@fdecapstone.com.161026, abarr@fdecapstone.com.161026, zcopman@fdecapstone.com.161026) as queue members.
>
> Step 2 — If any Step 1 deployment fails: automatically fall back to Slack escalation flow instead. Create an Autolaunched Flow named "EscalationToSlack" triggered when a Case with Issue_Classification__c is created from Aria. Flow posts to Slack channel C0C82MYADGW with: diner name, Reservation__c link, conversation transcript (Conversation_Transcript__c), recommended next action.
>
> Report which path was taken (Omni-Channel or Slack fallback) and what was deployed.

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
