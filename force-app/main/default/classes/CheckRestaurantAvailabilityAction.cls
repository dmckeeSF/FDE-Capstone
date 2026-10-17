/**
 * CheckRestaurantAvailabilityAction
 * @InvocableMethod — checks if a restaurant has available slots on a given date.
 * Counts non-cancelled reservations and compares against the restaurant's Max_Party_Size__c.
 * Throws AuraHandledException when no active restaurant matches the search term.
 */
public with sharing class CheckRestaurantAvailabilityAction {

    @InvocableMethod(label='Check Restaurant Availability' description='Checks if a restaurant has availability on a given date')
    public static List<AvailabilityResult> checkAvailability(List<AvailabilityRequest> requests) {
        AvailabilityRequest request = requests[0];
        String searchTerm = '%' + request.restaurantName + '%';

        List<Account> restaurants = [
            SELECT Id, Name, Max_Party_Size__c
            FROM Account
            WHERE RecordType.DeveloperName = 'Restaurant'
              AND Name LIKE :searchTerm
              AND Is_Active__c = true
            LIMIT 1
        ];

        if (restaurants.isEmpty()) {
            throw new AuraHandledException('Restaurant not found: ' + request.restaurantName);
        }

        Account restaurant = restaurants[0];
        Id restaurantId = restaurant.Id;
        Date reservationDate = request.reservationDate;

        Integer bookedCount = [
            SELECT COUNT()
            FROM Reservation__c
            WHERE Restaurant__c = :restaurantId
              AND Reservation_Date__c = :reservationDate
              AND Status__c != 'Cancelled'
        ];

        Integer maxPartySize = (restaurant.Max_Party_Size__c != null)
                                    ? Integer.valueOf(restaurant.Max_Party_Size__c)
                                    : 0;

        Integer availableSlots = Math.max(0, maxPartySize - bookedCount);
        Boolean isAvailable = availableSlots > 0;

        String formattedDate = String.valueOf(reservationDate);
        String message = isAvailable
            ? restaurant.Name + ' has ' + availableSlots + ' slot' + (availableSlots == 1 ? '' : 's') + ' available on ' + formattedDate + '.'
            : restaurant.Name + ' has no availability on ' + formattedDate + '.';

        AvailabilityResult result = new AvailabilityResult();
        result.isAvailable    = isAvailable;
        result.availableSlots = availableSlots;
        result.maxPartySize   = maxPartySize;
        result.bookedCount    = bookedCount;
        result.message        = message;

        return new List<AvailabilityResult>{ result };
    }

    public class AvailabilityRequest {
        @InvocableVariable(required=true) public String restaurantName;
        @InvocableVariable(required=true) public Date   reservationDate;
    }

    public class AvailabilityResult {
        @InvocableVariable public Boolean isAvailable;
        @InvocableVariable public Integer availableSlots;
        @InvocableVariable public Integer maxPartySize;
        @InvocableVariable public Integer bookedCount;
        @InvocableVariable public String  message;
    }
}