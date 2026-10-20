public with sharing class CreateReservationAction {

    @InvocableMethod(label='Create Reservation' description='Books a new reservation for a diner at a restaurant')
    public static List<CreateResult> createReservation(List<CreateRequest> requests) {
        CreateRequest req = requests[0];
        CreateResult result = new CreateResult();

        // Resolve restaurant by name (Restaurant record type only)
        List<Account> restaurants = [
            SELECT Id, Name
            FROM Account
            WHERE RecordType.DeveloperName = 'Restaurant'
              AND Name = :req.restaurantName
            LIMIT 1
        ];

        if (restaurants.isEmpty()) {
            result.isSuccess = false;
            result.message   = 'Restaurant "' + req.restaurantName + '" not found. Please check the name and try again.';
            return new List<CreateResult>{ result };
        }

        Id restaurantId = restaurants[0].Id;

        // Parse time string (HH:mm) into Time
        Time reservationTime;
        try {
            reservationTime = parseTime(req.reservationTime);
        } catch (Exception e) {
            result.isSuccess = false;
            result.message   = 'Invalid time format: "' + req.reservationTime + '". Please use HH:mm format (e.g. 19:30).';
            return new List<CreateResult>{ result };
        }

        Reservation__c res = new Reservation__c(
            Diner__c             = req.contactId,
            Restaurant__c        = restaurantId,
            Reservation_Date__c  = req.reservationDate,
            Reservation_Time__c  = reservationTime,
            Party_Size__c        = req.partySize != null ? req.partySize : 2,
            Status__c            = 'Confirmed',
            Special_Requests__c  = req.specialRequests
        );

        try {
            insert res;
        } catch (DmlException e) {
            result.isSuccess = false;
            result.message   = 'Could not create reservation: ' + e.getDmlMessage(0);
            return new List<CreateResult>{ result };
        }

        // Re-query to get the auto-generated booking reference
        res = [SELECT Id, Booking_Reference__c FROM Reservation__c WHERE Id = :res.Id];

        result.isSuccess        = true;
        result.bookingReference = res.Booking_Reference__c;
        result.restaurantName   = req.restaurantName;
        result.reservationDate  = String.valueOf(req.reservationDate);
        result.reservationTime  = req.reservationTime;
        result.partySize        = req.partySize != null ? req.partySize : 2;
        result.message          = 'Your reservation at ' + req.restaurantName
                                  + ' on ' + req.reservationDate
                                  + ' at ' + req.reservationTime
                                  + ' for ' + result.partySize + ' guest(s) has been confirmed.'
                                  + ' Your booking reference is ' + res.Booking_Reference__c + '.';

        return new List<CreateResult>{ result };
    }

    private static Time parseTime(String timeStr) {
        List<String> parts = timeStr.split(':');
        Integer hours   = Integer.valueOf(parts[0]);
        Integer minutes = Integer.valueOf(parts[1]);
        return Time.newInstance(hours, minutes, 0, 0);
    }

    public class CreateRequest {
        @InvocableVariable(required=true)  public String  restaurantName;
        @InvocableVariable(required=true)  public Date    reservationDate;
        @InvocableVariable(required=true)  public String  reservationTime;
        @InvocableVariable(required=true)  public String  contactId;
        @InvocableVariable(required=false) public Integer partySize;
        @InvocableVariable(required=false) public String  specialRequests;
    }

    public class CreateResult {
        @InvocableVariable public Boolean isSuccess;
        @InvocableVariable public String  bookingReference;
        @InvocableVariable public String  restaurantName;
        @InvocableVariable public String  reservationDate;
        @InvocableVariable public String  reservationTime;
        @InvocableVariable public Integer partySize;
        @InvocableVariable public String  message;
    }
}
