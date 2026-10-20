/**
 * CancelReservationAction
 * @InvocableMethod — cancels a reservation by booking reference.
 * Called by the Cancel_Reservation autolaunched flow.
 */
public with sharing class CancelReservationAction {

    @InvocableMethod(label='Cancel Reservation' description='Cancels a reservation by booking reference')
    public static List<String> execute(List<CancelInput> inputs) {
        List<String> results = new List<String>();
        for (CancelInput inp : inputs) {
            ReservationApiClient.ApiResponse resp =
                ReservationApiClient.cancelReservation(inp.bookingReference, inp.cancellationReason);
            if (!resp.isSuccess) {
                throw new AuraHandledException(resp.body);
            }
            results.add('Reservation ' + inp.bookingReference + ' has been cancelled.');
        }
        return results;
    }

    public class CancelInput {
        @InvocableVariable(required=true) public String bookingReference;
        @InvocableVariable                public String cancellationReason;
    }
}