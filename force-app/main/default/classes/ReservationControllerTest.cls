@IsTest
private class ReservationControllerTest {

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

    @TestSetup
    static void setup() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];
        insert new Account(Name = 'Aria Kitchen', RecordTypeId = rt.Id);
    }

    // ─── getRestaurants ────────────────────────────────────────────────────────

    @IsTest
    static void testGetRestaurantsReturnsList() {
        Test.startTest();
        List<ReservationController.RestaurantInfo> result = ReservationController.getRestaurants();
        Test.stopTest();

        System.assert(result.size() >= 1, 'Expected at least one restaurant');
        System.assertNotEquals(null, result[0].id);
        System.assertNotEquals(null, result[0].name);
    }

    @IsTest
    static void testGetRestaurantsReturnsEmptyWhenNone() {
        // Delete the restaurant inserted in setup
        Account a = [SELECT Id FROM Account WHERE Name = 'Aria Kitchen' LIMIT 1];
        delete a;

        Test.startTest();
        List<ReservationController.RestaurantInfo> result = ReservationController.getRestaurants();
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    // ─── getAvailableSlots ─────────────────────────────────────────────────────

    @IsTest
    static void testGetAvailableSlotsReturnsParsedSlots() {
        String mockBody = '{"slots":[' +
            '{"time":"12:00","available":true,"remaining":4},' +
            '{"time":"13:00","available":false,"remaining":0},' +
            '{"time":"19:00","available":true,"remaining":2}' +
            ']}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockBody));

        Test.startTest();
        List<ReservationController.TimeSlot> slots =
            ReservationController.getAvailableSlots('Aria Kitchen', '2026-12-01', 2);
        Test.stopTest();

        System.assertEquals(2, slots.size(), 'Only available slots should be returned');
        System.assertEquals('12:00', slots[0].slotTime);
        System.assertEquals(true, slots[0].available);
    }

    @IsTest
    static void testGetAvailableSlotsThrowsOnApiError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(500, '{"error":"Server error"}'));

        Boolean threw = false;
        Test.startTest();
        try {
            ReservationController.getAvailableSlots('Aria Kitchen', '2026-12-01', 2);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Should throw AuraHandledException on API error');
    }

    @IsTest
    static void testGetAvailableSlotsNullSlots() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{}'));

        Test.startTest();
        List<ReservationController.TimeSlot> slots =
            ReservationController.getAvailableSlots('Aria Kitchen', '2026-12-01', 2);
        Test.stopTest();

        System.assertEquals(0, slots.size(), 'No slots key → empty list');
    }

    // ─── createReservation — resolveContactId guard ────────────────────────────

    @IsTest
    static void testCreateReservationThrowsForInternalUser() {
        Boolean threw = false;
        Test.startTest();
        try {
            ReservationController.createReservation('Aria Kitchen', '2026-12-01', '19:00', 2, '');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Internal user has no ContactId — should throw');
    }

    // ─── getMyReservations — resolveContactId guard ────────────────────────────

    @IsTest
    static void testGetMyReservationsThrowsForInternalUser() {
        Boolean threw = false;
        Test.startTest();
        try {
            ReservationController.getMyReservations();
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Internal user has no ContactId — should throw');
    }

    // ─── cancelReservation — resolveContactId guard ────────────────────────────

    @IsTest
    static void testCancelReservationThrowsForInternalUser() {
        Boolean threw = false;
        Test.startTest();
        try {
            ReservationController.cancelReservation('RES-000001', 'Changed my mind');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Internal user has no ContactId — should throw');
    }
}
