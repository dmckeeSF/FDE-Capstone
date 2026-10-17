/**
 * ModifyReservationAction
 * @InvocableMethod — updates date, time, or party size for a reservation.
 * Called by the Modify_Reservation autolaunched flow.
 * newDate passed as ISO string (yyyy-MM-dd); newTime as HH:MM string.
 */
public with sharing class ModifyReservationAction {

    @InvocableMethod(label='Modify Reservation' description='Updates date, time, or party size for a reservation')
    public static List<GetReservationAction.ReservationDTO> execute(List<ModifyInput> inputs) {
        ModifyInput inp = inputs[0];
        ReservationApiClient.ApiResponse resp = ReservationApiClient.modifyReservation(
            inp.bookingReference,
            inp.newDate,
            inp.newTime,
            inp.newPartySize
        );
        if (!resp.isSuccess) {
            throw new AuraHandledException(resp.body);
        }
        return new List<GetReservationAction.ReservationDTO>{
            GetReservationAction.parseDTO(resp.body)
        };
    }

    public class ModifyInput {
        @InvocableVariable(required=true)  public String  bookingReference;
        @InvocableVariable                 public String  newDate;
        @InvocableVariable                 public String  newTime;
        @InvocableVariable                 public Integer newPartySize;
    }
}