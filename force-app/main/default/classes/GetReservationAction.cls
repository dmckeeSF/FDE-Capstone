/**
 * GetReservationAction
 * @InvocableMethod — retrieves reservation details by booking reference.
 * Called by the Get_Reservation_Details autolaunched flow.
 *
 * Note: The API returns "date" and "time" keys. Because those are reserved
 * identifiers in Apex, the DTO uses reservationDate / reservationTime and
 * we parse the JSON manually via Map<String, Object>.
 */
public with sharing class GetReservationAction {

    @InvocableMethod(label='Get Reservation Details' description='Retrieves reservation details by booking reference')
    public static List<ReservationDTO> execute(List<String> bookingReferences) {
        String bookingRef = bookingReferences[0];
        ReservationApiClient.ApiResponse resp = ReservationApiClient.getReservation(bookingRef);
        if (!resp.isSuccess) {
            throw new AuraHandledException(resp.body);
        }
        return new List<ReservationDTO>{ parseDTO(resp.body) };
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