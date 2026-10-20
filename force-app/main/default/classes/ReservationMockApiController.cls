@RestResource(urlMapping='/reservations/*')
global without sharing class ReservationMockApiController {

    // GET /reservations/{bookingRef}
    // GET /reservations/availability?restaurant=...&date=...&time=...&partySize=...
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String bookingRef = extractBookingRef(req.requestURI);

        if (bookingRef == 'availability') {
            doGetAvailability(req, res);
            return;
        }

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

    // ── availability ─────────────────────────────────────────────────────────

    private static void doGetAvailability(RestRequest req, RestResponse res) {
        String restaurantName = req.params.get('restaurant');
        String dateStr        = req.params.get('date');
        String timeStr        = req.params.get('time');
        String partySizeStr   = req.params.get('partySize');

        if (String.isBlank(restaurantName) || String.isBlank(dateStr)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"error":"restaurant and date are required"}');
            return;
        }

        List<Account> restaurants = [
            SELECT Id, Name, First_Seating__c, Second_Seating__c, Total_Covers__c
            FROM Account
            WHERE RecordType.DeveloperName = 'Restaurant'
              AND Name LIKE :('%' + restaurantName + '%')
              AND Is_Active__c = true
            LIMIT 1
        ];

        if (restaurants.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('{"error":"Restaurant not found"}');
            return;
        }

        Account rest       = restaurants[0];
        Date reserveDate   = Date.valueOf(dateStr);
        Integer partySize  = String.isBlank(partySizeStr) ? 2 : Integer.valueOf(partySizeStr);
        Integer totalCovers = rest.Total_Covers__c != null ? Integer.valueOf(rest.Total_Covers__c) : 60;
        String firstStart  = String.isNotBlank(rest.First_Seating__c)  ? rest.First_Seating__c  : '17:30';
        String secondStart = String.isNotBlank(rest.Second_Seating__c) ? rest.Second_Seating__c : '20:00';

        // Generate all 15-min slots across both seating windows (6 slots each = 90 min)
        List<Integer> allSlotMins = new List<Integer>();
        Integer firstMins  = toMinutes(firstStart);
        Integer secondMins = toMinutes(secondStart);
        for (Integer i = 0; i < 6; i++) {
            allSlotMins.add(firstMins  + i * 15);
            allSlotMins.add(secondMins + i * 15);
        }

        // Build a map of slotMinutes → bookedCovers for this date
        Map<Integer, Integer> bookedBySlot = new Map<Integer, Integer>();
        for (Integer m : allSlotMins) bookedBySlot.put(m, 0);

        for (AggregateResult ar : [
            SELECT Reservation_Time__c slotTime, SUM(Party_Size__c) covers
            FROM Reservation__c
            WHERE Restaurant__c = :rest.Id
              AND Reservation_Date__c = :reserveDate
              AND Status__c != 'Cancelled'
            GROUP BY Reservation_Time__c
        ]) {
            Time t = (Time) ar.get('slotTime');
            if (t == null) continue;
            Integer slotMins = t.hour() * 60 + t.minute();
            if (bookedBySlot.containsKey(slotMins)) {
                bookedBySlot.put(slotMins, Integer.valueOf(ar.get('covers')));
            }
        }

        // Filter to available slots only (booked + requested party fits within covers)
        List<Integer> availableMins = new List<Integer>();
        for (Integer slotMins : allSlotMins) {
            Integer booked = bookedBySlot.get(slotMins);
            if (booked == null) booked = 0;
            if (booked + partySize <= totalCovers) {
                availableMins.add(slotMins);
            }
        }

        // Sort by proximity to requested time, return up to 3
        Integer requestedMins = String.isBlank(timeStr) ? toMinutes(secondStart) : toMinutes(timeStr);
        availableMins.sort();
        // Find the 3 closest by absolute difference
        List<Integer> closest = pickClosest(availableMins, requestedMins, 3);

        // Build response
        List<String> slots = new List<String>();
        for (Integer m : closest) slots.add(toTimeStr(m));

        Map<String, Object> response = new Map<String, Object>{
            'restaurant'     => rest.Name,
            'date'           => dateStr,
            'requestedTime'  => timeStr,
            'partySize'      => partySize,
            'availableSlots' => slots
        };

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
    }

    private static Integer toMinutes(String hhmm) {
        List<String> parts = hhmm.split(':');
        return Integer.valueOf(parts[0]) * 60 + Integer.valueOf(parts[1]);
    }

    private static String toTimeStr(Integer totalMins) {
        Integer h = totalMins / 60;
        Integer m = Math.mod(totalMins, 60);
        String hStr = h < 10 ? '0' + h : String.valueOf(h);
        String mStr = m < 10 ? '0' + m : String.valueOf(m);
        return hStr + ':' + mStr;
    }

    // Pick up to n slots sorted closest to requestedMins
    private static List<Integer> pickClosest(List<Integer> sorted, Integer target, Integer n) {
        // Build a sorted-by-distance list preserving original order for ties
        List<Integer[]> byDist = new List<Integer[]>();
        for (Integer i = 0; i < sorted.size(); i++) {
            byDist.add(new Integer[]{ Math.abs(sorted[i] - target), sorted[i] });
        }
        // Simple insertion sort by distance
        for (Integer i = 1; i < byDist.size(); i++) {
            Integer[] key = byDist[i];
            Integer j = i - 1;
            while (j >= 0 && byDist[j][0] > key[0]) {
                byDist[j + 1] = byDist[j];
                j--;
            }
            byDist[j + 1] = key;
        }
        List<Integer> result = new List<Integer>();
        for (Integer i = 0; i < Math.min(n, byDist.size()); i++) {
            result.add(byDist[i][1]);
        }
        result.sort();
        return result;
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