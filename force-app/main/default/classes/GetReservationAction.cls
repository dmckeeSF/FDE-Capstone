/**
 * GetReservationAction
 * @InvocableMethod — retrieves reservation details by booking reference.
 * Requires contactId (from @MessagingEndUser.ContactId) to verify ownership
 * before any callout, so no diner can read another's reservation.
 */
public with sharing class GetReservationAction {

    @InvocableMethod(label='Get Reservation Details' description='Retrieves reservation details by booking reference')
    public static List<ReservationDTO> execute(List<GetRequest> requests) {
        List<ReservationDTO> results = new List<ReservationDTO>();
        for (GetRequest req : requests) {
            verifyOwnership(req.bookingReference, req.contactId);
            ReservationApiClient.ApiResponse resp = ReservationApiClient.getReservation(req.bookingReference);
            if (!resp.isSuccess) {
                throw new AuraHandledException(resp.body);
            }
            results.add(parseDTO(resp.body));
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

    @TestVisible
    public static ReservationDTO parseDTO(String jsonBody) {
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
        ReservationDTO dto     = new ReservationDTO();
        dto.bookingReference   = (String)  m.get('bookingReference');
        dto.status             = (String)  m.get('status');
        dto.restaurantName     = (String)  m.get('restaurantName');
        dto.dinerName          = (String)  m.get('dinerName');
        dto.reservationDate    = (String)  m.get('date');
        dto.reservationTime    = (String)  m.get('time');
        dto.partySize          = (Integer) m.get('partySize');
        dto.specialRequests    = (String)  m.get('specialRequests');
        return dto;
    }

    public class GetRequest {
        @InvocableVariable(required=true label='Booking Reference') public String bookingReference;
        @InvocableVariable(required=true label='Contact Id')        public String contactId;
    }

    public class ReservationDTO {
        @InvocableVariable public String  bookingReference;
        @InvocableVariable public String  status;
        @InvocableVariable public String  restaurantName;
        @InvocableVariable public String  dinerName;
        @InvocableVariable public String  reservationDate;
        @InvocableVariable public String  reservationTime;
        @InvocableVariable public Integer partySize;
        @InvocableVariable public String  specialRequests;
    }
}
