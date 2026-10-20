/**
 * RestaurantActionTest
 * Unit tests for GetRestaurantInfoAction and CheckRestaurantAvailabilityAction.
 * Uses @TestSetup to create one Restaurant Account + 3 Confirmed Reservations.
 * Target: 90%+ coverage across both action classes.
 */
@IsTest
private class RestaurantActionTest {

    private static final String RESTAURANT_NAME = 'The Grand Bistro';
    private static final Date   TEST_DATE       = Date.newInstance(2027, 3, 15);

    // ─── Test Setup ──────────────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        // Query RecordTypeId dynamically — no hardcoded IDs
        Id restaurantRTId = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Account'
              AND DeveloperName = 'Restaurant'
            LIMIT 1
        ].Id;

        Account restaurant = new Account(
            Name                 = RESTAURANT_NAME,
            RecordTypeId         = restaurantRTId,
            Cuisine_Type__c      = 'French',
            Operating_Hours__c   = 'Mon-Sun 12:00-22:00',
            Cancellation_Policy__c = '24-hour notice required',
            Price_Range__c       = '$$$',
            Dress_Code__c        = 'Smart Casual',
            Accessibility_Info__c = 'Wheelchair accessible entrance',
            Max_Party_Size__c    = 10,
            Is_Active__c         = true
        );
        insert restaurant;

        // Create a Contact for the Master-Detail Diner__c relationship
        Contact diner = new Contact(LastName = 'TestDiner');
        insert diner;

        // 3 Confirmed reservations on TEST_DATE
        List<Reservation__c> reservations = new List<Reservation__c>();
        for (Integer i = 0; i < 3; i++) {
            reservations.add(new Reservation__c(
                Restaurant__c       = restaurant.Id,
                Diner__c            = diner.Id,
                Reservation_Date__c = TEST_DATE,
                Reservation_Time__c = Time.newInstance(19, 0, 0, 0),
                Party_Size__c       = 2,
                Status__c           = 'Confirmed'
            ));
        }
        insert reservations;
    }

    // ─── GetRestaurantInfoAction ──────────────────────────────────────────────────

    @IsTest
    static void testGetRestaurantInfo_found() {
        Test.startTest();
        List<GetRestaurantInfoAction.RestaurantDTO> results =
            GetRestaurantInfoAction.getRestaurantInfo(
                new List<String>{ RESTAURANT_NAME }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one DTO');
        GetRestaurantInfoAction.RestaurantDTO dto = results[0];
        System.assertEquals(RESTAURANT_NAME,             dto.name,                'Name should match');
        System.assertEquals('French',                    dto.cuisineType,         'Cuisine type should match');
        System.assertEquals('Mon-Sun 12:00-22:00',       dto.operatingHours,      'Operating hours should match');
        System.assertEquals('24-hour notice required',   dto.cancellationPolicy,  'Cancellation policy should match');
        System.assertEquals('$$$',                       dto.priceRange,          'Price range should match');
        System.assertEquals('Smart Casual',              dto.dressCode,           'Dress code should match');
        System.assertEquals('Wheelchair accessible entrance', dto.accessibilityInfo, 'Accessibility info should match');
        System.assertEquals(10,                          dto.maxPartySize,        'Max party size should be 10');
        System.assertEquals(true,                        dto.isActive,            'Is active should be true');
    }

    @IsTest
    static void testGetRestaurantInfo_fuzzy() {
        Test.startTest();
        // Partial name — just "Grand" — should still resolve
        List<GetRestaurantInfoAction.RestaurantDTO> results =
            GetRestaurantInfoAction.getRestaurantInfo(
                new List<String>{ 'Grand' }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Fuzzy search should return one DTO');
        System.assertEquals(RESTAURANT_NAME, results[0].name, 'Should resolve to The Grand Bistro');
    }

    @IsTest
    static void testGetRestaurantInfo_notFound() {
        Test.startTest();
        Boolean threw = false;
        try {
            GetRestaurantInfoAction.getRestaurantInfo(
                new List<String>{ 'ZZZNOMATCH' }
            );
        } catch (AuraHandledException ex) {
            threw = true;
            System.assert(ex.getMessage() != null, 'Exception message should not be null');
        }
        Test.stopTest();

        System.assert(threw, 'AuraHandledException should have been thrown for missing restaurant');
    }

    // ─── Callout mock ─────────────────────────────────────────────────────────────

    private class AvailabilityMock implements HttpCalloutMock {
        private Integer statusCode;
        private String  body;
        AvailabilityMock(Integer sc, String b) { statusCode = sc; body = b; }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    private static final String SLOTS_JSON = '{"restaurant":"' + RESTAURANT_NAME + '","date":"2027-03-15","availableSlots":["17:30","17:45","18:00"],"timeZone":"America/New_York"}';
    private static final String NO_SLOTS_JSON = '{"restaurant":"' + RESTAURANT_NAME + '","date":"2027-03-15","availableSlots":[],"timeZone":"America/New_York"}';
    private static final String NOT_FOUND_JSON_AVAIL = '{"error":"Restaurant not found"}';

    // ─── CheckRestaurantAvailabilityAction ────────────────────────────────────────

    @IsTest
    static void testCheckAvailability_hasSlots() {
        Test.setMock(HttpCalloutMock.class, new AvailabilityMock(200, SLOTS_JSON));

        CheckRestaurantAvailabilityAction.AvailabilityRequest req =
            new CheckRestaurantAvailabilityAction.AvailabilityRequest();
        req.restaurantName  = RESTAURANT_NAME;
        req.reservationDate = TEST_DATE;
        req.partySize       = 2;

        Test.startTest();
        List<CheckRestaurantAvailabilityAction.AvailabilityResult> results =
            CheckRestaurantAvailabilityAction.checkAvailability(
                new List<CheckRestaurantAvailabilityAction.AvailabilityRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        CheckRestaurantAvailabilityAction.AvailabilityResult result = results[0];
        System.assertEquals(true, result.isAvailable, 'Should be available');
        System.assert(!result.availableSlots.isEmpty(), 'Should have available time slots');
        System.assert(result.message.contains(RESTAURANT_NAME), 'Message should contain restaurant name');
    }

    @IsTest
    static void testCheckAvailability_noSlots() {
        Test.setMock(HttpCalloutMock.class, new AvailabilityMock(200, NO_SLOTS_JSON));

        CheckRestaurantAvailabilityAction.AvailabilityRequest req =
            new CheckRestaurantAvailabilityAction.AvailabilityRequest();
        req.restaurantName  = RESTAURANT_NAME;
        req.reservationDate = TEST_DATE;
        req.partySize       = 2;

        Test.startTest();
        List<CheckRestaurantAvailabilityAction.AvailabilityResult> results =
            CheckRestaurantAvailabilityAction.checkAvailability(
                new List<CheckRestaurantAvailabilityAction.AvailabilityRequest>{ req }
            );
        Test.stopTest();

        CheckRestaurantAvailabilityAction.AvailabilityResult result = results[0];
        System.assertEquals(false, result.isAvailable, 'Should not be available when fully booked');
        System.assert(result.availableSlots.isEmpty(), 'Available slots list should be empty');
    }

    @IsTest
    static void testCheckAvailability_notFound() {
        Test.setMock(HttpCalloutMock.class, new AvailabilityMock(404, NOT_FOUND_JSON_AVAIL));

        CheckRestaurantAvailabilityAction.AvailabilityRequest req =
            new CheckRestaurantAvailabilityAction.AvailabilityRequest();
        req.restaurantName  = 'ZZZNOMATCH';
        req.reservationDate = TEST_DATE;

        Test.startTest();
        List<CheckRestaurantAvailabilityAction.AvailabilityResult> results =
            CheckRestaurantAvailabilityAction.checkAvailability(
                new List<CheckRestaurantAvailabilityAction.AvailabilityRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        CheckRestaurantAvailabilityAction.AvailabilityResult result = results[0];
        System.assertEquals(false, result.isAvailable, 'Should not be available for unknown restaurant');
    }
}