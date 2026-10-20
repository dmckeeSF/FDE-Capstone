public with sharing class CreateReservationAction {

    @InvocableMethod(label='Create Reservation' description='Books a new reservation for a diner at a restaurant')
    public static List<CreateResult> createReservation(List<CreateRequest> requests) {
        // Collect all restaurant names for a single SOQL
        Set<String> names = new Set<String>();
        for (CreateRequest req : requests) {
            if (String.isNotBlank(req.restaurantName)) names.add(req.restaurantName);
        }

        Map<String, Id> restaurantIdByName = new Map<String, Id>();
        for (Account a : [
            SELECT Id, Name
            FROM Account
            WHERE RecordType.DeveloperName = 'Restaurant'
              AND Name IN :names
        ]) {
            restaurantIdByName.put(a.Name, a.Id);
        }

        // Build all reservation records and track which request each maps to
        List<CreateResult> results = new List<CreateResult>();
        List<Reservation__c> toInsert = new List<Reservation__c>();
        List<Integer> insertIndexes = new List<Integer>();

        for (Integer i = 0; i < requests.size(); i++) {
            CreateRequest req = requests[i];
            CreateResult result = new CreateResult();
            results.add(result);

            if (!restaurantIdByName.containsKey(req.restaurantName)) {
                result.isSuccess = false;
                result.message   = 'Restaurant "' + req.restaurantName + '" not found. Please check the name and try again.';
                continue;
            }

            Time reservationTime;
            try {
                reservationTime = parseTime(req.reservationTime);
            } catch (Exception e) {
                result.isSuccess = false;
                result.message   = 'Invalid time format: "' + req.reservationTime + '". Please use HH:mm format (e.g. 19:30).';
                continue;
            }

            toInsert.add(new Reservation__c(
                Diner__c             = req.contactId,
                Restaurant__c        = restaurantIdByName.get(req.restaurantName),
                Reservation_Date__c  = req.reservationDate,
                Reservation_Time__c  = reservationTime,
                Party_Size__c        = req.partySize != null ? req.partySize : 2,
                Status__c            = 'Confirmed',
                Special_Requests__c  = req.specialRequests
            ));
            insertIndexes.add(i);
        }

        // Single bulk DML
        if (!toInsert.isEmpty()) {
            Database.SaveResult[] saveResults = Database.insert(toInsert, false);

            // Re-query to get auto-generated booking references in one SOQL
            Set<Id> insertedIds = new Set<Id>();
            for (Integer j = 0; j < saveResults.size(); j++) {
                if (saveResults[j].isSuccess()) insertedIds.add(saveResults[j].getId());
            }
            Map<Id, String> bookingRefById = new Map<Id, String>();
            for (Reservation__c r : [SELECT Id, Booking_Reference__c FROM Reservation__c WHERE Id IN :insertedIds]) {
                bookingRefById.put(r.Id, r.Booking_Reference__c);
            }

            for (Integer j = 0; j < saveResults.size(); j++) {
                Integer reqIdx = insertIndexes[j];
                CreateRequest req = requests[reqIdx];
                CreateResult result = results[reqIdx];
                if (saveResults[j].isSuccess()) {
                    String bookingRef = bookingRefById.get(saveResults[j].getId());
                    result.isSuccess        = true;
                    result.bookingReference = bookingRef;
                    result.restaurantName   = req.restaurantName;
                    result.reservationDate  = String.valueOf(req.reservationDate);
                    result.reservationTime  = req.reservationTime;
                    result.partySize        = req.partySize != null ? req.partySize : 2;
                    result.message          = 'Your reservation at ' + req.restaurantName
                                              + ' on ' + req.reservationDate
                                              + ' at ' + req.reservationTime
                                              + ' for ' + result.partySize + ' guest(s) has been confirmed.'
                                              + ' Your booking reference is ' + bookingRef + '.';
                } else {
                    result.isSuccess = false;
                    result.message   = 'Could not create reservation: ' + saveResults[j].getErrors()[0].getMessage();
                }
            }
        }

        return results;
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
