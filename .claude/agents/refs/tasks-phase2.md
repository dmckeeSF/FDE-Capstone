# Phase 2 — Integration Layer Tasks

## TASK-D2
Launch `adlc-engineer`:
> Create Apex class `ReservationMockApiController` with `@RestResource(urlMapping='/reservations/*')`. Implement:
> - GET: accepts bookingRef path param, queries Reservation__c WHERE Booking_Reference__c = bookingRef, returns JSON: {id, bookingReference, status, restaurantName, dinerName, date, time, partySize, specialRequests}
> - PATCH: accepts bookingRef + JSON body {newDate, newTime, newPartySize}, updates Reservation__c record, returns updated JSON
> - DELETE: accepts bookingRef + optional cancellationReason, sets Status__c=Cancelled, Cancelled_At__c=now, returns {bookingReference, status:'Cancelled', cancelledAt}
> Include test class with 90%+ coverage. Deploy to FdeCap.

## TASK-D3
Launch `adlc-engineer`:
> Create External Credential `Reservation_API_Ext_Cred` (No Auth principal). Create Named Credential `Reservation_API` pointing to FdeCap org's own domain + /services/apexrest. Create 3 HTTP Callout Actions: GetReservationDetails (GET /reservations/{bookingRef}), ModifyReservation (PATCH /reservations/{bookingRef}), CancelReservation (DELETE /reservations/{bookingRef}). Deploy to FdeCap.

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
