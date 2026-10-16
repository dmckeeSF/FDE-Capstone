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
