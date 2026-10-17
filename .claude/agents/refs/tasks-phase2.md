# Phase 2 — Integration Layer Tasks

## TASK-D2
Launch `adlc-engineer`:
> Create Apex class `ReservationMockApiController` with `@RestResource(urlMapping='/reservations/*')`. Implement:
> - GET: accepts bookingRef path param, queries Reservation__c WHERE Booking_Reference__c = bookingRef, returns JSON: {id, bookingReference, status, restaurantName, dinerName, date, time, partySize, specialRequests}
> - PATCH: accepts bookingRef + JSON body {newDate, newTime, newPartySize}, updates Reservation__c record, returns updated JSON
> - DELETE: accepts bookingRef + optional cancellationReason, sets Status__c=Cancelled, Cancelled_At__c=now, returns {bookingReference, status:'Cancelled', cancelledAt}
> Include test class with 90%+ coverage. Deploy to FdeCap.

### Permission Set Steps (TASK-D2)
After Apex class and test class deploy:
1. Update `Aria_Agent_Access` — add Apex class access for `ReservationMockApiController`:
   ```xml
   <classAccesses>
     <apexClass>ReservationMockApiController</apexClass>
     <enabled>true</enabled>
   </classAccesses>
   ```
2. Deploy the updated `Aria_Agent_Access`.
3. Update TASK-D2 record:
   ```bash
   sf data update record --sobject Build_Task__c --where "Name='TASK-D2'" \
     --values "Notes__c='ReservationMockApiController deployed. Aria_Agent_Access updated with Apex class access.' Status__c='Done'" \
     --target-org FdeCap
   ```

## TASK-D3
Launch `adlc-engineer`:
> Create External Credential `Reservation_API_Ext_Cred` (No Auth principal). Create Named Credential `Reservation_API` pointing to FdeCap org's own domain + /services/apexrest. Create 3 HTTP Callout Actions: GetReservationDetails (GET /reservations/{bookingRef}), ModifyReservation (PATCH /reservations/{bookingRef}), CancelReservation (DELETE /reservations/{bookingRef}). Deploy to FdeCap.

### Permission Set Steps (TASK-D3)
Named Credentials are org-level and don't require per-user FLS. No permission set changes needed for TASK-D3.
Update TASK-D3 record on completion:
```bash
sf data update record --sobject Build_Task__c --where "Name='TASK-D3'" \
  --values "Notes__c='Named Credential + External Credential + 3 HTTP Callout Actions deployed. No PS changes required (Named Creds are org-level).' Status__c='Done'" \
  --target-org FdeCap
```

## TASK-D4
Launch `adlc-engineer`:
> Create 3 @InvocableMethod Apex classes and corresponding Autolaunched Flows for use as Agent Actions:
>
> 1. GetReservationAction — Input: bookingReference (String). Calls Named Credential GET. Returns: ReservationDTO (id, bookingReference, status, restaurantName, dinerName, date, time, partySize). Fault path: creates Case (Priority=High, Issue_Classification__c=Booking Issue), returns error message.
>
> 2. ModifyReservationAction — Inputs: bookingReference, newDate (Date), newTime (Time), newPartySize (Integer). Calls PATCH. Returns updated ReservationDTO. Fault path: creates Case, escalates.
>
> 3. CancelReservationAction — Inputs: bookingReference, cancellationReason (String). Calls DELETE. Returns confirmation String. Fault path: creates Case, escalates.
>
> Include test classes with 90%+ coverage. Deploy to FdeCap.

### Permission Set Steps (TASK-D4)
After the 3 Apex classes and 3 Autolaunched Flows deploy:
1. Update `Aria_Agent_Access` — add Apex class access for all 3 invocable classes:
   ```xml
   <classAccesses>
     <apexClass>GetReservationAction</apexClass><enabled>true</enabled>
   </classAccesses>
   <classAccesses>
     <apexClass>ModifyReservationAction</apexClass><enabled>true</enabled>
   </classAccesses>
   <classAccesses>
     <apexClass>CancelReservationAction</apexClass><enabled>true</enabled>
   </classAccesses>
   ```
2. Deploy the updated `Aria_Agent_Access`.
3. Update TASK-D4 record:
   ```bash
   sf data update record --sobject Build_Task__c --where "Name='TASK-D4'" \
     --values "Notes__c='3 invocable Apex classes + Autolaunched Flows deployed. Aria_Agent_Access updated with all 3 Apex class grants.' Status__c='Done'" \
     --target-org FdeCap
   ```
