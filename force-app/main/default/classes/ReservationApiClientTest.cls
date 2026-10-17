/**
 * ReservationApiClientTest
 * Unit tests for ReservationApiClient — uses HttpCalloutMock to avoid real callouts.
 * Target: 90%+ coverage of ReservationApiClient.
 */
@IsTest
private class ReservationApiClientTest {

    // ─── Mock helpers ─────────────────────────────────────────────────────────

    private class MockHttpResponse implements HttpCalloutMock {
        private final Integer statusCode;
        private final String  body;

        MockHttpResponse(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body       = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    private static final String BOOKING_REF = 'RES-TEST-001';

    private static final String RESERVATION_JSON =
        '{"id":"aaaaaa","bookingReference":"' + BOOKING_REF + '",' +
        '"status":"Confirmed","restaurantName":"Aria Kitchen",' +
        '"dinerName":"Jane Doe","date":"2025-11-15","time":"19:00:00",' +
        '"partySize":2,"specialRequests":null}';

    private static final String CANCELLED_JSON =
        '{"bookingReference":"' + BOOKING_REF + '",' +
        '"status":"Cancelled","cancelledAt":"2025-11-10T12:00:00Z"}';

    private static final String NOT_FOUND_JSON = '{"error":"Reservation not found"}';

    // ─── getReservation ───────────────────────────────────────────────────────

    @IsTest
    static void testGetReservation_success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, RESERVATION_JSON));
        Test.startTest();
        ReservationApiClient.ApiResponse resp = ReservationApiClient.getReservation(BOOKING_REF);
        Test.stopTest();

        System.assertEquals(200, resp.statusCode, 'Status code should be 200');
        System.assertEquals(true, resp.isSuccess, 'isSuccess should be true for 2xx');
        System.assert(resp.body.contains(BOOKING_REF), 'Body should contain booking reference');
    }

    @IsTest
    static void testGetReservation_notFound() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(404, NOT_FOUND_JSON));
        Test.startTest();
        ReservationApiClient.ApiResponse resp = ReservationApiClient.getReservation('DOES-NOT-EXIST');
        Test.stopTest();

        System.assertEquals(404, resp.statusCode, 'Status code should be 404');
        System.assertEquals(false, resp.isSuccess, 'isSuccess should be false for 4xx');
    }

    // ─── modifyReservation ────────────────────────────────────────────────────

    @IsTest
    static void testModifyReservation_allFields() {
        String modifiedJson = RESERVATION_JSON.replace('"Confirmed"', '"Modified"');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, modifiedJson));
        Test.startTest();
        ReservationApiClient.ApiResponse resp = ReservationApiClient.modifyReservation(
            BOOKING_REF, '2025-12-20', '20:00', 4
        );
        Test.stopTest();

        System.assertEquals(200, resp.statusCode, 'Status code should be 200');
        System.assertEquals(true, resp.isSuccess, 'isSuccess should be true');
    }

    @IsTest
    static void testModifyReservation_dateOnly() {
        String modifiedJson = RESERVATION_JSON.replace('"Confirmed"', '"Modified"');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, modifiedJson));
        Test.startTest();
        ReservationApiClient.ApiResponse resp = ReservationApiClient.modifyReservation(
            BOOKING_REF, '2025-12-20', null, null
        );
        Test.stopTest();

        System.assertEquals(200, resp.statusCode, 'Status should be 200 for date-only modify');
    }

    @IsTest
    static void testModifyReservation_partySizeOnly() {
        String modifiedJson = RESERVATION_JSON.replace('"Confirmed"', '"Modified"');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, modifiedJson));
        Test.startTest();
        ReservationApiClient.ApiResponse resp = ReservationApiClient.modifyReservation(
            BOOKING_REF, null, null, 6
        );
        Test.stopTest();

        System.assertEquals(200, resp.statusCode, 'Status should be 200 for party-size-only modify');
    }

    @IsTest
    static void testModifyReservation_notFound() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(404, NOT_FOUND_JSON));
        Test.startTest();
        ReservationApiClient.ApiResponse resp = ReservationApiClient.modifyReservation(
            'DOES-NOT-EXIST', '2025-12-20', '19:00', 2
        );
        Test.stopTest();

        System.assertEquals(404, resp.statusCode, 'Status should be 404 for missing reservation');
        System.assertEquals(false, resp.isSuccess, 'isSuccess should be false');
    }

    // ─── cancelReservation ────────────────────────────────────────────────────

    @IsTest
    static void testCancelReservation_withReason() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, CANCELLED_JSON));
        Test.startTest();
        ReservationApiClient.ApiResponse resp = ReservationApiClient.cancelReservation(
            BOOKING_REF, 'Change of plans'
        );
        Test.stopTest();

        System.assertEquals(200, resp.statusCode, 'Status code should be 200');
        System.assertEquals(true, resp.isSuccess, 'isSuccess should be true');
        System.assert(resp.body.contains('Cancelled'), 'Body should confirm cancellation');
    }

    @IsTest
    static void testCancelReservation_noReason() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, CANCELLED_JSON));
        Test.startTest();
        ReservationApiClient.ApiResponse resp = ReservationApiClient.cancelReservation(
            BOOKING_REF, null
        );
        Test.stopTest();

        System.assertEquals(200, resp.statusCode, 'Status code should be 200 without reason');
        System.assertEquals(true, resp.isSuccess, 'isSuccess should be true');
    }

    @IsTest
    static void testCancelReservation_blankReason() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, CANCELLED_JSON));
        Test.startTest();
        ReservationApiClient.ApiResponse resp = ReservationApiClient.cancelReservation(
            BOOKING_REF, '   '
        );
        Test.stopTest();

        System.assertEquals(200, resp.statusCode, 'Blank reason should still succeed');
    }

    @IsTest
    static void testCancelReservation_notFound() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(404, NOT_FOUND_JSON));
        Test.startTest();
        ReservationApiClient.ApiResponse resp = ReservationApiClient.cancelReservation(
            'DOES-NOT-EXIST', 'No show'
        );
        Test.stopTest();

        System.assertEquals(404, resp.statusCode, 'Status should be 404 for missing reservation');
        System.assertEquals(false, resp.isSuccess, 'isSuccess should be false');
    }

    // ─── isSuccess boundary ───────────────────────────────────────────────────

    @IsTest
    static void testIsSuccess_serverError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(500, '{"error":"internal"}'));
        Test.startTest();
        ReservationApiClient.ApiResponse resp = ReservationApiClient.getReservation(BOOKING_REF);
        Test.stopTest();

        System.assertEquals(500, resp.statusCode, 'Status should be 500');
        System.assertEquals(false, resp.isSuccess, 'isSuccess should be false for 5xx');
    }
}