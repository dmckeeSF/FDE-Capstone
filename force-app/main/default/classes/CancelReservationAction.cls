/**
 * CancelReservationAction
 * @InvocableMethod — cancels a reservation by booking reference.
 * Called by the Cancel_Reservation autolaunched flow.
 */
public with sharing class CancelReservationAction {

    @InvocableMethod(label='Cancel Reservation' description='Cancels a reservation by booking reference')
    public static List<String> execute(List<CancelInput> inputs) {
        CancelInput inp = inputs[0];
        ReservationApiClient.ApiResponse resp =
            ReservationApiClient.cancelReservation(inp.bookingReference, inp.cancellationReason);
        if (!resp.isSuccess) {
            throw new AuraHandledException(resp.body);
        }
        String confirmation = 'Reservation ' + inp.bookingReference + ' has been cancelled.';
        return new List<String>{ confirmation };
    }

    public class CancelInput {
        @InvocableVariable(required=true) public String bookingReference;
        @InvocableVariable                public String cancellationReason;
    }
}