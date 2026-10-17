@RestResource(urlMapping='/reservations/*')
global without sharing class ReservationMockApiController {

    // GET /reservations/{bookingRef}
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String bookingRef = extractBookingRef(req.requestURI);

        List<Reservation__c> reservations = [
            SELECT Id, Booking_Reference__c, Status__c,
                   Restaurant__r.Name,
                   Diner__r.FirstName, Diner__r.LastName,
                   Reservation_Date__c, Reservation_Time__c,
                   Party_Size__c, Special_Requests__c
            FROM Reservation__c
            WHERE Booking_Reference__c = :bookingRef
            LIMIT 1
        ];

        if (reservations.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('{"error":"Reservation not found"}');
            return;
        }

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(buildReservationMap(reservations[0])));
    }

    // PATCH /reservations/{bookingRef}
    @HttpPatch
    global static void doPatch() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String bookingRef = extractBookingRef(req.requestURI);

        List<Reservation__c> reservations = [
            SELECT Id, Booking_Reference__c, Status__c,
                   Restaurant__r.Name,
                   Diner__r.FirstName, Diner__r.LastName,
                   Reservation_Date__c, Reservation_Time__c,
                   Party_Size__c, Special_Requests__c
            FROM Reservation__c
            WHERE Booking_Reference__c = :bookingRef
            LIMIT 1
        ];

        if (reservations.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('{"error":"Reservation not found"}');
            return;
        }

        Reservation__c reservation = reservations[0];
        Date originalDate = reservation.Reservation_Date__c;

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
            req.requestBody.toString()
        );

        if (body.containsKey('newDate')) {
            reservation.Reservation_Date__c = Date.valueOf((String) body.get('newDate'));
        }
        if (body.containsKey('newTime')) {
            reservation.Reservation_Time__c = parseTime((String) body.get('newTime'));
        }
        if (body.containsKey('newPartySize')) {
            Object ps = body.get('newPartySize');
            reservation.Party_Size__c = ps instanceof Integer
                ? (Integer) ps
                : Integer.valueOf(String.valueOf(ps));
        }

        reservation.Status__c = 'Modified';
        reservation.Modified_At__c = DateTime.now();
        reservation.Original_Reservation_Date__c = originalDate;

        update reservation;

        Reservation__c updated = [
            SELECT Id, Booking_Reference__c, Status__c,
                   Restaurant__r.Name,
                   Diner__r.FirstName, Diner__r.LastName,
                   Reservation_Date__c, Reservation_Time__c,
                   Party_Size__c, Special_Requests__c
            FROM Reservation__c
            WHERE Id = :reservation.Id
            LIMIT 1
        ];

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(buildReservationMap(updated)));
    }

    // DELETE /reservations/{bookingRef}
    @HttpDelete
    global static void doDelete() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String bookingRef = extractBookingRef(req.requestURI);

        List<Reservation__c> reservations = [
            SELECT Id, Booking_Reference__c, Status__c
            FROM Reservation__c
            WHERE Booking_Reference__c = :bookingRef
            LIMIT 1
        ];

        if (reservations.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('{"error":"Reservation not found"}');
            return;
        }

        Reservation__c reservation = reservations[0];

        String cancellationReason = null;
        if (req.requestBody != null && String.isNotBlank(req.requestBody.toString())) {
            try {
                Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
                    req.requestBody.toString()
                );
                cancellationReason = (String) body.get('cancellationReason');
            } catch (Exception e) {
                // ignore malformed body
            }
        }

        DateTime cancelledAt = DateTime.now();
        reservation.Status__c = 'Cancelled';
        reservation.Cancelled_At__c = cancelledAt;
        if (String.isNotBlank(cancellationReason)) {
            reservation.Cancellation_Reason__c = cancellationReason;
        }

        update reservation;

        Map<String, Object> response = new Map<String, Object>{
            'bookingReference' => reservation.Booking_Reference__c,
            'status' => 'Cancelled',
            'cancelledAt' => cancelledAt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
        };

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private static String extractBookingRef(String uri) {
        List<String> parts = uri.split('/');
        return parts[parts.size() - 1];
    }

    private static Map<String, Object> buildReservationMap(Reservation__c r) {
        return new Map<String, Object>{
            'id'              => r.Id,
            'bookingReference'=> r.Booking_Reference__c,
            'status'          => r.Status__c,
            'restaurantName'  => r.Restaurant__r != null ? r.Restaurant__r.Name : null,
            'dinerName'       => buildDinerName(r),
            'date'            => r.Reservation_Date__c != null
                                    ? String.valueOf(r.Reservation_Date__c) : null,
            'time'            => r.Reservation_Time__c != null
                                    ? String.valueOf(r.Reservation_Time__c) : null,
            'partySize'       => r.Party_Size__c != null
                                    ? r.Party_Size__c.intValue() : null,
            'specialRequests' => r.Special_Requests__c
        };
    }

    private static String buildDinerName(Reservation__c r) {
        if (r.Diner__r == null) { return null; }
        String first = r.Diner__r.FirstName != null ? r.Diner__r.FirstName : '';
        String last  = r.Diner__r.LastName  != null ? r.Diner__r.LastName  : '';
        return (first + ' ' + last).trim();
    }

    // Accepts HH:MM or HH:MM:SS
    private static Time parseTime(String t) {
        List<String> parts = t.split(':');
        Integer h  = Integer.valueOf(parts[0]);
        Integer m  = parts.size() > 1 ? Integer.valueOf(parts[1]) : 0;
        Integer s  = parts.size() > 2 ? Integer.valueOf(parts[2].split('\\.')[0]) : 0;
        return Time.newInstance(h, m, s, 0);
    }
}