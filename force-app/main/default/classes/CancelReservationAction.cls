/**
 * CancelReservationAction
 * @InvocableMethod — cancels a reservation by booking reference.
 * Requires contactId (from @MessagingEndUser.ContactId) to verify ownership.
 */
public with sharing class CancelReservationAction {

    @InvocableMethod(label='Cancel Reservation' description='Cancels a reservation by booking reference')
    public static List<String> execute(List<CancelInput> inputs) {
        List<String> results = new List<String>();
        for (CancelInput inp : inputs) {
            verifyOwnership(inp.bookingReference, inp.contactId);
            ReservationApiClient.ApiResponse resp =
                ReservationApiClient.cancelReservation(inp.bookingReference, inp.cancellationReason);
            if (!resp.isSuccess) {
                throw new AuraHandledException(resp.body);
            }
            results.add('Reservation ' + inp.bookingReference + ' has been cancelled.');
        }
        return results;
    }

    private static void verifyOwnership(String bookingRef, String contactId) {
        if (String.isBlank(contactId)) {
            throw new AuraHandledException('Contact ID required for reservation access.');
        }
        List<Reservation__c> check = [
            SELECT Id FROM Reservation__c
            WHERE Booking_Reference__c = :bookingRef
              AND Diner__c             = :contactId
            LIMIT 1
        ];
        if (check.isEmpty()) {
            throw new AuraHandledException('Reservation not found.');
        }
    }

    public class CancelInput {
        @InvocableVariable(required=true label='Booking Reference') public String bookingReference;
        @InvocableVariable(required=true label='Contact Id')        public String contactId;
        @InvocableVariable(label='Cancellation Reason')             public String cancellationReason;
    }
}
