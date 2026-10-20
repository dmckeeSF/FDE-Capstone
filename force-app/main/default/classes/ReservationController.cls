/**
 * ReservationController
 * @AuraEnabled Apex for ariaDiningBooking LWC — callable from Experience Cloud.
 * Resolves contactId from the running community user (no LLM input accepted).
 */
public with sharing class ReservationController {

    // ─── Restaurant List ───────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<RestaurantInfo> getRestaurants() {
        List<RestaurantInfo> results = new List<RestaurantInfo>();
        for (Account a : [
            SELECT Id, Name, Description, Phone,
                   Total_Covers__c, First_Seating__c, Second_Seating__c, Dining_Time_Zone__c
            FROM Account
            WHERE RecordType.DeveloperName = 'Restaurant'
            ORDER BY Name
        ]) {
            RestaurantInfo info  = new RestaurantInfo();
            info.id              = a.Id;
            info.name            = a.Name;
            info.description     = a.Description;
            info.phone           = a.Phone;
            info.firstSeating    = a.First_Seating__c;
            info.secondSeating   = a.Second_Seating__c;
            info.timeZone        = a.Dining_Time_Zone__c;
            results.add(info);
        }
        return results;
    }

    // ─── Availability ──────────────────────────────────────────────────────────

    @AuraEnabled
    public static List<TimeSlot> getAvailableSlots(
        String restaurantName,
        String reservationDate,
        Integer partySize
    ) {
        ReservationApiClient.ApiResponse resp =
            ReservationApiClient.getAvailability(restaurantName, reservationDate, '', partySize);
        if (!resp.isSuccess) {
            throw new AuraHandledException(resp.body);
        }

        List<TimeSlot> slots = new List<TimeSlot>();
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(resp.body);
        List<Object> rawSlots = (List<Object>) payload.get('slots');
        if (rawSlots == null) return slots;

        for (Object raw : rawSlots) {
            Map<String, Object> s = (Map<String, Object>) raw;
            TimeSlot ts      = new TimeSlot();
            ts.slotTime      = (String)  s.get('time');
            ts.available     = (Boolean) s.get('available');
            ts.remaining     = s.get('remaining') != null
                ? Integer.valueOf(String.valueOf(s.get('remaining'))) : null;
            if (ts.available) slots.add(ts);
        }
        return slots;
    }

    // ─── Create Reservation ────────────────────────────────────────────────────

    @AuraEnabled
    public static BookingResult createReservation(
        String restaurantName,
        String reservationDate,
        String reservationTime,
        Integer partySize,
        String specialRequests
    ) {
        String dinerId = resolveContactId();

        CreateReservationAction.CreateRequest req = new CreateReservationAction.CreateRequest();
        req.restaurantName   = restaurantName;
        req.reservationDate  = Date.valueOf(reservationDate);
        req.reservationTime  = reservationTime;
        req.partySize        = partySize;
        req.contactId        = dinerId;
        req.specialRequests  = specialRequests;

        List<CreateReservationAction.CreateResult> results =
            CreateReservationAction.createReservation(
                new List<CreateReservationAction.CreateRequest>{ req }
            );

        CreateReservationAction.CreateResult r = results[0];
        BookingResult br       = new BookingResult();
        br.isSuccess           = r.isSuccess;
        br.bookingReference    = r.bookingReference;
        br.restaurantName      = r.restaurantName;
        br.reservationDate     = r.reservationDate;
        br.reservationTime     = r.reservationTime;
        br.partySize           = r.partySize;
        br.message             = r.message;
        return br;
    }

    // ─── Current Diner Reservations ────────────────────────────────────────────

    @AuraEnabled(cacheable=false)
    public static List<ReservationSummary> getMyReservations() {
        String contactId = resolveContactId();
        List<ReservationSummary> summaries = new List<ReservationSummary>();
        for (Reservation__c r : [
            SELECT Booking_Reference__c, Status__c,
                   Restaurant__r.Name, Restaurant__r.Dining_Time_Zone__c,
                   Reservation_Date__c, Reservation_Time__c, Party_Size__c
            FROM Reservation__c
            WHERE Diner__c = :contactId
              AND Status__c != 'Cancelled'
              AND Reservation_Date__c >= TODAY
            ORDER BY Reservation_Date__c ASC, Reservation_Time__c ASC
            LIMIT 10
        ]) {
            ReservationSummary s    = new ReservationSummary();
            s.bookingReference      = r.Booking_Reference__c;
            s.status                = r.Status__c;
            s.restaurantName        = r.Restaurant__r.Name;
            s.timeZone              = r.Restaurant__r.Dining_Time_Zone__c;
            s.reservationDate       = r.Reservation_Date__c != null
                ? String.valueOf(r.Reservation_Date__c) : null;
            s.reservationTime       = r.Reservation_Time__c != null
                ? String.valueOf(r.Reservation_Time__c) : null;
            s.partySize             = r.Party_Size__c != null
                ? Integer.valueOf(r.Party_Size__c) : null;
            summaries.add(s);
        }
        return summaries;
    }

    // ─── Cancel Reservation ────────────────────────────────────────────────────

    @AuraEnabled
    public static String cancelReservation(String bookingReference, String reason) {
        String dinerId = resolveContactId();

        CancelReservationAction.CancelInput inp = new CancelReservationAction.CancelInput();
        inp.bookingReference   = bookingReference;
        inp.contactId          = dinerId;
        inp.cancellationReason = reason;

        List<String> results = CancelReservationAction.execute(
            new List<CancelReservationAction.CancelInput>{ inp }
        );
        return results[0];
    }

    // ─── Helpers ───────────────────────────────────────────────────────────────

    private static String resolveContactId() {
        Id userId = UserInfo.getUserId();
        List<User> users = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];
        if (users.isEmpty() || users[0].ContactId == null) {
            throw new AuraHandledException('You must be logged in as a registered diner.');
        }
        return users[0].ContactId;
    }

    // ─── Inner classes (wire / return shapes) ─────────────────────────────────

    public class RestaurantInfo {
        @AuraEnabled public String  id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  description;
        @AuraEnabled public String  phone;
        @AuraEnabled public String  firstSeating;
        @AuraEnabled public String  secondSeating;
        @AuraEnabled public String  timeZone;
    }

    public class TimeSlot {
        @AuraEnabled public String  slotTime;
        @AuraEnabled public Boolean available;
        @AuraEnabled public Integer remaining;
    }

    public class BookingResult {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String  bookingReference;
        @AuraEnabled public String  restaurantName;
        @AuraEnabled public String  reservationDate;
        @AuraEnabled public String  reservationTime;
        @AuraEnabled public Integer partySize;
        @AuraEnabled public String  message;
    }

    public class ReservationSummary {
        @AuraEnabled public String  bookingReference;
        @AuraEnabled public String  status;
        @AuraEnabled public String  restaurantName;
        @AuraEnabled public String  timeZone;
        @AuraEnabled public String  reservationDate;
        @AuraEnabled public String  reservationTime;
        @AuraEnabled public Integer partySize;
    }
}
