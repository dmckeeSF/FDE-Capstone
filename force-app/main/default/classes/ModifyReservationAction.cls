/**
 * ModifyReservationAction
 * @InvocableMethod — updates date, time, or party size for a reservation.
 * Requires contactId (from @MessagingEndUser.ContactId) to verify ownership.
 * newDate passed as ISO string (yyyy-MM-dd); newTime as HH:MM string.
 */
public with sharing class ModifyReservationAction {

    @InvocableMethod(label='Modify Reservation' description='Updates date, time, or party size for a reservation')
    public static List<GetReservationAction.ReservationDTO> execute(List<ModifyInput> inputs) {
        List<GetReservationAction.ReservationDTO> results = new List<GetReservationAction.ReservationDTO>();
        for (ModifyInput inp : inputs) {
            verifyOwnership(inp.bookingReference, inp.contactId);
            ReservationApiClient.ApiResponse resp = ReservationApiClient.modifyReservation(
                inp.bookingReference,
                inp.newDate,
                inp.newTime,
                inp.newPartySize
            );
            if (!resp.isSuccess) {
                throw new AuraHandledException(resp.body);
            }
            results.add(GetReservationAction.parseDTO(resp.body));
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

    public class ModifyInput {
        @InvocableVariable(required=true label='Booking Reference') public String  bookingReference;
        @InvocableVariable(required=true label='Contact Id')        public String  contactId;
        @InvocableVariable(label='New Date (yyyy-MM-dd)')           public String  newDate;
        @InvocableVariable(label='New Time (HH:mm)')                public String  newTime;
        @InvocableVariable(label='New Party Size')                  public Integer newPartySize;
    }
}
