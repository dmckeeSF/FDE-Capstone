/**
 * ReservationActionTest
 * Unit tests for GetReservationAction, ModifyReservationAction, CancelReservationAction.
 * Uses HttpCalloutMock — no real callouts.
 * Target: 90%+ coverage across all three action classes.
 */
@IsTest
private class ReservationActionTest {

    // ─── Shared mock ─────────────────────────────────────────────────────────────

    private class MockHttp implements HttpCalloutMock {
        private final Integer code;
        private final String  body;
        MockHttp(Integer code, String body) {
            this.code = code;
            this.body = body;
        }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = new HttpResponse();
            r.setStatusCode(code);
            r.setBody(body);
            return r;
        }
    }

    private static final String BOOKING_REF = 'RES-000001';

    private static final String RESERVATION_JSON =
        '{"bookingReference":"' + BOOKING_REF + '",' +
        '"status":"Confirmed","restaurantName":"Aria Kitchen",' +
        '"dinerName":"Jane Doe","date":"2025-11-15","time":"19:00:00",' +
        '"partySize":2,"specialRequests":"Window seat please"}';

    private static final String MODIFIED_JSON =
        '{"bookingReference":"' + BOOKING_REF + '",' +
        '"status":"Confirmed","restaurantName":"Aria Kitchen",' +
        '"dinerName":"Jane Doe","date":"2025-12-20","time":"20:00:00",' +
        '"partySize":4,"specialRequests":null}';

    private static final String ERROR_BODY = '{"error":"Internal server error"}';

    // ─── GetReservationAction — happy path ────────────────────────────────────

    @IsTest
    static void testGetReservation_success() {
        Test.setMock(HttpCalloutMock.class, new MockHttp(200, RESERVATION_JSON));
        Test.startTest();
        List<GetReservationAction.ReservationDTO> results =
            GetReservationAction.execute(new List<String>{ BOOKING_REF });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one DTO');
        GetReservationAction.ReservationDTO dto = results[0];
        System.assertEquals(BOOKING_REF,         dto.bookingReference,  'Booking ref should match');
        System.assertEquals('Confirmed',         dto.status,            'Status should be Confirmed');
        System.assertEquals('Aria Kitchen',      dto.restaurantName,    'Restaurant name should match');
        System.assertEquals('Jane Doe',          dto.dinerName,         'Diner name should match');
        System.assertEquals('2025-11-15',        dto.reservationDate,   'Date should map correctly');
        System.assertEquals('19:00:00',          dto.reservationTime,   'Time should map correctly');
        System.assertEquals(2,                   dto.partySize,         'Party size should be 2');
        System.assertEquals('Window seat please',dto.specialRequests,   'Special requests should match');
    }

    // ─── GetReservationAction — fault path ────────────────────────────────────

    @IsTest
    static void testGetReservation_failure_throwsException() {
        Test.setMock(HttpCalloutMock.class, new MockHttp(500, ERROR_BODY));
        Test.startTest();
        Boolean threw = false;
        try {
            GetReservationAction.execute(new List<String>{ BOOKING_REF });
        } catch (AuraHandledException ex) {
            threw = true;
            System.assert(ex.getMessage() != null, 'Exception message should not be null');
        }
        Test.stopTest();

        System.assert(threw, 'AuraHandledException should have been thrown on 500');
    }

    // ─── ModifyReservationAction — happy path ─────────────────────────────────

    @IsTest
    static void testModifyReservation_success() {
        Test.setMock(HttpCalloutMock.class, new MockHttp(200, MODIFIED_JSON));
        ModifyReservationAction.ModifyInput inp = new ModifyReservationAction.ModifyInput();
        inp.bookingReference = BOOKING_REF;
        inp.newDate          = '2025-12-20';
        inp.newTime          = '20:00';
        inp.newPartySize     = 4;

        Test.startTest();
        List<GetReservationAction.ReservationDTO> results =
            ModifyReservationAction.execute(new List<ModifyReservationAction.ModifyInput>{ inp });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one DTO');
        System.assertEquals('2025-12-20', results[0].reservationDate, 'Date should be updated');
        System.assertEquals(4,            results[0].partySize,       'Party size should be updated');
    }

    @IsTest
    static void testModifyReservation_dateOnly() {
        String dateOnlyJson = RESERVATION_JSON.replace('"2025-11-15"', '"2025-12-01"');
        Test.setMock(HttpCalloutMock.class, new MockHttp(200, dateOnlyJson));
        ModifyReservationAction.ModifyInput inp = new ModifyReservationAction.ModifyInput();
        inp.bookingReference = BOOKING_REF;
        inp.newDate          = '2025-12-01';

        Test.startTest();
        List<GetReservationAction.ReservationDTO> results =
            ModifyReservationAction.execute(new List<ModifyReservationAction.ModifyInput>{ inp });
        Test.stopTest();

        System.assertEquals('2025-12-01', results[0].reservationDate, 'Date should be updated');
    }

    // ─── ModifyReservationAction — fault path ─────────────────────────────────

    @IsTest
    static void testModifyReservation_failure_throwsException() {
        Test.setMock(HttpCalloutMock.class, new MockHttp(500, ERROR_BODY));
        ModifyReservationAction.ModifyInput inp = new ModifyReservationAction.ModifyInput();
        inp.bookingReference = BOOKING_REF;
        inp.newPartySize     = 6;

        Test.startTest();
        Boolean threw = false;
        try {
            ModifyReservationAction.execute(new List<ModifyReservationAction.ModifyInput>{ inp });
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'AuraHandledException should have been thrown on 500');
    }

    // ─── CancelReservationAction — happy path ─────────────────────────────────

    @IsTest
    static void testCancelReservation_success() {
        String cancelledBody = '{"bookingReference":"' + BOOKING_REF + '","status":"Cancelled"}';
        Test.setMock(HttpCalloutMock.class, new MockHttp(200, cancelledBody));
        CancelReservationAction.CancelInput inp = new CancelReservationAction.CancelInput();
        inp.bookingReference  = BOOKING_REF;
        inp.cancellationReason = 'Change of plans';

        Test.startTest();
        List<String> results =
            CancelReservationAction.execute(new List<CancelReservationAction.CancelInput>{ inp });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one confirmation message');
        System.assert(results[0].contains(BOOKING_REF),    'Confirmation should contain booking ref');
        System.assert(results[0].contains('cancelled'),    'Confirmation should say cancelled');
    }

    @IsTest
    static void testCancelReservation_noReason() {
        String cancelledBody = '{"bookingReference":"' + BOOKING_REF + '","status":"Cancelled"}';
        Test.setMock(HttpCalloutMock.class, new MockHttp(200, cancelledBody));
        CancelReservationAction.CancelInput inp = new CancelReservationAction.CancelInput();
        inp.bookingReference = BOOKING_REF;

        Test.startTest();
        List<String> results =
            CancelReservationAction.execute(new List<CancelReservationAction.CancelInput>{ inp });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one confirmation even without reason');
    }

    // ─── CancelReservationAction — fault path ─────────────────────────────────

    @IsTest
    static void testCancelReservation_failure_throwsException() {
        Test.setMock(HttpCalloutMock.class, new MockHttp(500, ERROR_BODY));
        CancelReservationAction.CancelInput inp = new CancelReservationAction.CancelInput();
        inp.bookingReference  = BOOKING_REF;
        inp.cancellationReason = 'Test failure';

        Test.startTest();
        Boolean threw = false;
        try {
            CancelReservationAction.execute(new List<CancelReservationAction.CancelInput>{ inp });
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'AuraHandledException should have been thrown on 500');
    }

    // ─── CreateReservationAction ──────────────────────────────────────────────

    private static final String RESTAURANT_NAME = 'Test Create Bistro';

    private static Account createTestRestaurant() {
        Id restaurantRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1].Id;
        Account a = new Account(Name = RESTAURANT_NAME, RecordTypeId = restaurantRT);
        insert a;
        return a;
    }

    private static Contact createTestDiner(Id accountId) {
        Contact c = new Contact(FirstName = 'Create', LastName = 'Test', Email = 'createtest@test.com', AccountId = accountId);
        insert c;
        return c;
    }

    @IsTest
    static void testCreateReservation_success() {
        Account rest = createTestRestaurant();
        Contact diner = createTestDiner(rest.Id);

        CreateReservationAction.CreateRequest req = new CreateReservationAction.CreateRequest();
        req.restaurantName  = RESTAURANT_NAME;
        req.reservationDate = Date.today().addDays(10);
        req.reservationTime = '19:30';
        req.contactId       = diner.Id;
        req.partySize       = 2;

        Test.startTest();
        List<CreateReservationAction.CreateResult> results =
            CreateReservationAction.createReservation(new List<CreateReservationAction.CreateRequest>{ req });
        Test.stopTest();

        Assert.areEqual(1, results.size());
        CreateReservationAction.CreateResult res = results[0];
        Assert.isTrue(res.isSuccess, 'Reservation should be created successfully');
        Assert.isNotNull(res.bookingReference, 'Booking reference must be returned');
        Assert.isTrue(res.bookingReference.startsWith('RES-'), 'Booking reference must follow RES-XXXXXX format');
        Assert.areEqual(RESTAURANT_NAME, res.restaurantName);
        Assert.areEqual(2, res.partySize);
    }

    @IsTest
    static void testCreateReservation_restaurantNotFound() {
        Account rest = createTestRestaurant();
        Contact diner = createTestDiner(rest.Id);

        CreateReservationAction.CreateRequest req = new CreateReservationAction.CreateRequest();
        req.restaurantName  = 'No Such Restaurant XYZ';
        req.reservationDate = Date.today().addDays(10);
        req.reservationTime = '18:00';
        req.contactId       = diner.Id;
        req.partySize       = 2;

        Test.startTest();
        List<CreateReservationAction.CreateResult> results =
            CreateReservationAction.createReservation(new List<CreateReservationAction.CreateRequest>{ req });
        Test.stopTest();

        Assert.isFalse(results[0].isSuccess, 'Should fail when restaurant not found');
        Assert.isTrue(results[0].message.contains('not found'), 'Message must describe the failure');
    }
}