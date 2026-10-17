# Phase 5 — Data Cloud Tasks

## TASK-D13
Launch `adlc-engineer`:
> Phase 1 Data Cloud setup in FdeCap (read-only grounding, no activation segments):
>
> 1. Enable Data Cloud in FdeCap org if not already enabled.
>
> 2. Create Data Stream from Contact object, mapping to Unified Individual DMO:
>    Fields: Id, FirstName, LastName, Email, Membership_Number__c, Loyalty_Tier__c, Dietary_Preferences__c
>
> 3. Create Data Stream from Reservation__c object, mapping to custom DMO named "Unified_Reservation":
>    Fields: Id, Booking_Reference__c, Status__c, Reservation_Date__c, Party_Size__c, Restaurant__c (lookup), Diner__c (lookup)
>
> 4. Configure Identity Resolution: match on Email field + Membership_Number__c. Link Unified Individual to Unified_Reservation via Contact Id.
>
> 5. Surface Unified Individual profile as grounding context for Aria: loyalty tier, booking count, preferred cuisine — available as read-only context in agent responses. No activation, no segment creation.
>
> Report the Data Cloud org URL and confirm both data streams are active.

### Permission Set Steps (TASK-D13)
After Data Cloud is enabled and data streams are configured:
1. Assign the Data Cloud Admin permission set to Destiny (required to manage data streams):
   ```bash
   DC_PS=$(sf data query \
     --query "SELECT Name FROM PermissionSet WHERE Name='SalesforceAdminForDataCloud' OR Name='DataCloudAdministrator' LIMIT 1" \
     --target-org FdeCap --json | jq -r '.result.records[0].Name // empty')
   sf org assign permset --name "$DC_PS" --on-behalf-of dmckee@fdecapstone.com.161026 --target-org FdeCap
   ```
2. Update TASK-D13 record:
   ```bash
   sf data update record --sobject Build_Task__c --where "Name='TASK-D13'" \
     --values "Notes__c='Data Cloud enabled. Contact + Reservation data streams active. Identity resolution configured. Data Cloud Admin PS assigned to Destiny.' Status__c='Done'" \
     --target-org FdeCap
   ```
