# Phase 1 — Data Foundation Tasks

## TASK-D1
Launch `adlc-engineer`:
> Deploy the following to FdeCap using metadata XML. Full field spec is in `.claude/docs/build-plan.md` (Data Model Specification section).
>
> - Account Record Type `Restaurant` with custom fields: Cuisine_Type__c (Picklist), Operating_Hours__c (Long Text), Cancellation_Policy__c (Long Text), Price_Range__c (Picklist: $/$$/$$$/$$$$), Dress_Code__c (Picklist: Casual/Smart Casual/Formal), Accessibility_Info__c (Long Text), Max_Party_Size__c (Number), Is_Active__c (Checkbox default true)
> - Reservation__c junction object: Master-Detail to Account (label: Restaurant), Master-Detail to Contact (label: Diner), plus fields: Reservation_Date__c (Date, req), Reservation_Time__c (Time, req), Party_Size__c (Number, req), Status__c (Picklist: Confirmed/Modified/Cancelled/No-Show, req), Booking_Reference__c (Auto-Number RES-{000000}, External ID, unique), Special_Requests__c (Long Text), Cancellation_Reason__c (Picklist: Change of Plans/Weather/Other), Cancelled_At__c (DateTime), Original_Reservation_Date__c (Date), Modified_At__c (DateTime)
> - Contact custom fields: Membership_Number__c (Text 20, External ID, unique), Loyalty_Tier__c (Picklist: Standard/Gold/Platinum), Dietary_Preferences__c (Multi-Select Picklist), Preferred_Cuisine__c (Picklist)
> - Case custom fields: Reservation__c (Lookup to Reservation__c), Conversation_Transcript__c (Long Text), Issue_Classification__c (Picklist: Booking Issue/Policy Question/Complaint/Other)
> - MessagingSession custom fields: ContactId__c (Text 18), MembershipNumber__c (Text 20), IsAuthenticated__c (Checkbox), LoyaltyTier__c (Text 20), BookingReference__c (Text 20)
> - Build_Task__c custom object: Name (Text), Status__c (Picklist: Pending/In Progress/Ready for Review/Done/Failed), Owner__c (Text), Notes__c (Long Text), Completed_At__c (DateTime)
> - Permission Set Aria_Agent_Access: Read on Account/Contact/Reservation__c/Knowledge; Create+Edit on Case; Edit Status__c/Cancelled_At__c/Modified_At__c/Original_Reservation_Date__c on Reservation__c

## TASK-Z1 (AI generates, Zach reviews)
Launch `adlc-engineer`:
> Using sf CLI, create the following records in FdeCap org using dynamic queries for all IDs — no hardcoded record IDs:
> - 5 Account records (Record Type: Restaurant) with realistic names, addresses, cuisine types, operating hours, cancellation policies
> - 10 Contact records as diners including Sofia Rodriguez (Email: sofiarodriguez@example.com, Membership_Number__c: 10008155, Loyalty_Tier__c: Gold)
> - 20 Reservation__c records linking contacts to restaurants: 10 Confirmed, 5 Modified, 5 Cancelled

After completion, mark `Ready for Review` and send Slack notification to Zach (zachary.copman@salesforce.com).
