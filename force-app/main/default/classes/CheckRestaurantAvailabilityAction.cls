public with sharing class CheckRestaurantAvailabilityAction {

    @InvocableMethod(label='Check Restaurant Availability' description='Returns up to 3 available time slots near the requested time, OpenTable-style')
    public static List<AvailabilityResult> checkAvailability(List<AvailabilityRequest> requests) {
        AvailabilityRequest request = requests[0];

        ReservationApiClient.ApiResponse apiRes = ReservationApiClient.getAvailability(
            request.restaurantName,
            request.reservationDate != null ? String.valueOf(request.reservationDate) : null,
            request.requestedTime,
            request.partySize != null ? request.partySize : 2
        );

        AvailabilityResult result = new AvailabilityResult();

        if (!apiRes.isSuccess) {
            result.isAvailable   = false;
            result.availableSlots = new List<String>();
            result.message       = 'No availability found for ' + request.restaurantName
                                   + ' on ' + request.reservationDate + '.';
            return new List<AvailabilityResult>{ result };
        }

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(apiRes.body);
        List<Object> rawSlots = (List<Object>) body.get('availableSlots');

        List<String> slots = new List<String>();
        if (rawSlots != null) {
            for (Object s : rawSlots) slots.add(String.valueOf(s));
        }

        result.isAvailable    = !slots.isEmpty();
        result.availableSlots = slots;
        result.restaurantName = String.valueOf(body.get('restaurant'));
        result.date           = String.valueOf(body.get('date'));

        if (slots.isEmpty()) {
            result.message = request.restaurantName + ' is fully booked on ' + request.reservationDate + '.';
        } else {
            result.message = 'Available times at ' + result.restaurantName
                             + ' on ' + result.date + ': ' + String.join(slots, ', ') + '.';
        }

        return new List<AvailabilityResult>{ result };
    }

    public class AvailabilityRequest {
        @InvocableVariable(required=true)  public String  restaurantName;
        @InvocableVariable(required=true)  public Date    reservationDate;
        @InvocableVariable(required=false) public String  requestedTime;
        @InvocableVariable(required=false) public Integer partySize;
    }

    public class AvailabilityResult {
        @InvocableVariable public Boolean      isAvailable;
        @InvocableVariable public List<String> availableSlots;
        @InvocableVariable public String       restaurantName;
        @InvocableVariable public String       date;
        @InvocableVariable public String       message;
    }
}
