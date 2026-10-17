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
> - Build_Task__c Tab: create a custom tab (list view style, default on) so the object is accessible from the App Launcher and navigation bar
> - Build_Task__c List Views: create two list views — "All Tasks" (all records, columns: Name, Status__c, Owner__c, Notes__c, Completed_At__c, sorted by CreatedDate ASC) and "My Tasks" (filtered by Owner__c = current user's name, same columns). Make both list views visible to all users.
> - Permission Set Aria_Agent_Access: Read on Account/Contact/Reservation__c/Knowledge; Create+Edit on Case; Edit Status__c/Cancelled_At__c/Modified_At__c/Original_Reservation_Date__c on Reservation__c; Read on Build_Task__c (so all team members can view task state)

### Permission Set Steps (TASK-D1)
After all metadata deploys successfully:
1. The spec above includes creating `Aria_Agent_Access`. Verify it deployed with all listed object/field permissions.
2. Create `Build_Task_Team_Access` — `viewAllFields: true`, Read+Create+Edit on `Build_Task__c`, `viewAllRecords: true`.
3. Assign both permission sets:
   ```bash
   # Build_Task_Team_Access → all three team members
   sf org assign permset --name Build_Task_Team_Access --on-behalf-of dmckee@fdecapstone.com.161026 --target-org FdeCap
   sf org assign permset --name Build_Task_Team_Access --on-behalf-of abarr@fdecapstone.com.161026 --target-org FdeCap
   sf org assign permset --name Build_Task_Team_Access --on-behalf-of zcopman@fdecapstone.com.161026 --target-org FdeCap
   # Aria_Agent_Access → Destiny for testing now; Aria bot user assigned in TASK-D5
   sf org assign permset --name Aria_Agent_Access --on-behalf-of dmckee@fdecapstone.com.161026 --target-org FdeCap
   ```
4. Deploy the **Aria Build Tracker** Lightning app (`Build_Task_App`) with tabs: Home, Build_Task__c, Account, Contact. Required metadata fields:
   ```xml
   <formFactors>Large</formFactors>
   <formFactors>Small</formFactors>
   <defaultLandingTab>Build_Task__c</defaultLandingTab>
   <navType>Standard</navType>
   <uiType>Lightning</uiType>
   <tabs>standard-home</tabs>
   <tabs>Build_Task__c</tabs>
   <tabs>standard-Account</tabs>
   <tabs>standard-Contact</tabs>
   ```
   Deploy the app first, then the permission set (PS references the app by name):
   ```bash
   sf project deploy start --metadata "CustomApplication:Build_Task_App" --target-org FdeCap
   sf project deploy start --metadata "PermissionSet:Build_Task_Team_Access" --target-org FdeCap
   ```

5. Deploy the **Admin profile** with two additions — tab visibility and default app. Without both, the tab will not appear in the nav bar even if the app is configured correctly:
   ```xml
   <applicationVisibilities>
       <application>Build_Task_App</application>
       <default>true</default>
       <visible>true</visible>
   </applicationVisibilities>
   <tabVisibilities>
       <tab>Build_Task__c</tab>
       <visibility>DefaultOn</visibility>
   </tabVisibilities>
   ```
   ```bash
   sf project deploy start --metadata "Profile:Admin" --target-org FdeCap
   ```
   > **Note:** `tabVisibilities DefaultOn` is required. Custom tabs default to `DefaultOff` for all profiles — the app can reference the tab but it won't render without this profile setting.

6. Update TASK-D1 record:
   ```bash
   sf data update record --sobject Build_Task__c --where "Name='TASK-D1'" \
     --values "Notes__c='Full data model deployed. 43 components. Aria_Agent_Access + Build_Task_Team_Access created. All 3 users assigned Build_Task_Team_Access. Build_Task_App deployed. Admin profile: tab DefaultOn + app default=true.' Status__c='Done'" \
     --target-org FdeCap
   ```

## TASK-Z1 (AI generates, Zach reviews)
Launch `adlc-engineer`:
> Using sf CLI, create the following records in FdeCap org using dynamic queries for all IDs — no hardcoded record IDs:
> - 5 Account records (Record Type: Restaurant) with realistic names, addresses, cuisine types, operating hours, cancellation policies
> - 10 Contact records as diners including Sofia Rodriguez (Email: sofiarodriguez@example.com, Membership_Number__c: 10008155, Loyalty_Tier__c: Gold)
> - 20 Reservation__c records linking contacts to restaurants: 10 Confirmed, 5 Modified, 5 Cancelled

After completion, mark `Ready for Review` and send Slack notification to channel C0C82MYADGW. The notification must include:
1. What was created (record counts)
2. Direct SOQL queries Zach can paste into the Developer Console or Workbench to review the data
3. The org login URL for FdeCap (`sf org display --target-org FdeCap --json | jq -r '.result.instanceUrl'`)

Template:
```
*TASK-Z1 ready for your review* 🍽️

@Zach — AI-generated mock data is loaded in FdeCap and ready for review.

*Created:*
• 5 Restaurant Accounts
• 10 Diner Contacts (including Sofia Rodriguez)
• 20 Reservations (10 Confirmed, 5 Modified, 5 Cancelled)

*Review the data — paste these into Developer Console (FdeCap org > Setup > Developer Console > Query Editor):*
```
SELECT Name, Cuisine_Type__c, Price_Range__c, Operating_Hours__c FROM Account WHERE RecordType.DeveloperName='Restaurant'
SELECT FirstName, LastName, Email, Membership_Number__c, Loyalty_Tier__c FROM Contact WHERE Membership_Number__c != null
SELECT Booking_Reference__c, Status__c, Restaurant__r.Name, Diner__r.FirstName, Diner__r.LastName, Reservation_Date__c, Party_Size__c FROM Reservation__c ORDER BY CreatedDate ASC
```

*Org login:* <instanceUrl>/lightning/o/Account/list?filterName=Recent

*To approve:* Open the Aria Build Tracker app → Build Tasks tab → TASK-Z1 → change Status to Done.
Questions? Ping @Destiny.
```
