/**
 * ReservationApiClient
 * Thin HTTP wrapper over the Reservation API Named Credential.
 * D4 @InvocableMethod classes call these three static methods.
 *
 * Named Credential: Reservation_API  →  <instance>/services/apexrest
 * Endpoint pattern: callout:Reservation_API/reservations/{bookingRef}
 */
public with sharing class ReservationApiClient {

    private static final String BASE_PATH = '/reservations/';

    // ─── Response wrapper ────────────────────────────────────────────────────

    public class ApiResponse {
        public Integer statusCode;
        public String  body;
        public Boolean isSuccess {
            get { return statusCode >= 200 && statusCode < 300; }
        }
    }

    // ─── GET /reservations/{bookingRef} ──────────────────────────────────────

    public static ApiResponse getReservation(String bookingRef) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('callout:Reservation_API' + BASE_PATH + EncodingUtil.urlEncode(bookingRef, 'UTF-8'));
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        return send(req);
    }

    // ─── PATCH /reservations/{bookingRef} ────────────────────────────────────

    /**
     * @param bookingRef  Reservation booking reference
     * @param newDate     ISO date string (yyyy-MM-dd), may be null
     * @param newTime     Time string (HH:mm or HH:mm:ss), may be null
     * @param newPartySize Positive integer, may be null
     */
    public static ApiResponse modifyReservation(
        String bookingRef,
        String newDate,
        String newTime,
        Integer newPartySize
    ) {
        Map<String, Object> payload = new Map<String, Object>();
        if (String.isNotBlank(newDate))  { payload.put('newDate',      newDate); }
        if (String.isNotBlank(newTime))  { payload.put('newTime',      newTime); }
        if (newPartySize != null)        { payload.put('newPartySize', newPartySize); }

        HttpRequest req = new HttpRequest();
        req.setMethod('PATCH');
        req.setEndpoint('callout:Reservation_API' + BASE_PATH + EncodingUtil.urlEncode(bookingRef, 'UTF-8'));
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(JSON.serialize(payload));
        return send(req);
    }

    // ─── DELETE /reservations/{bookingRef} ───────────────────────────────────

    /**
     * @param bookingRef         Reservation booking reference
     * @param cancellationReason Human-readable reason, may be null
     */
    public static ApiResponse cancelReservation(String bookingRef, String cancellationReason) {
        Map<String, Object> payload = new Map<String, Object>();
        if (String.isNotBlank(cancellationReason)) {
            payload.put('cancellationReason', cancellationReason);
        }

        HttpRequest req = new HttpRequest();
        req.setMethod('DELETE');
        req.setEndpoint('callout:Reservation_API' + BASE_PATH + EncodingUtil.urlEncode(bookingRef, 'UTF-8'));
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        if (!payload.isEmpty()) {
            req.setBody(JSON.serialize(payload));
        }
        return send(req);
    }

    // ─── private helpers ─────────────────────────────────────────────────────

    @TestVisible
    private static ApiResponse send(HttpRequest req) {
        Http http = new Http();
        HttpResponse res = http.send(req);
        ApiResponse apiRes = new ApiResponse();
        apiRes.statusCode = res.getStatusCode();
        apiRes.body       = res.getBody();
        return apiRes;
    }
}