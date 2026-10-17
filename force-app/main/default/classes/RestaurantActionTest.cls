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

    // ─── CheckRestaurantAvailabilityAction ────────────────────────────────────────

    @IsTest
    static void testCheckAvailability_hasSlots() {
        // Max 10, 3 booked on TEST_DATE → 7 available
        CheckRestaurantAvailabilityAction.AvailabilityRequest req =
            new CheckRestaurantAvailabilityAction.AvailabilityRequest();
        req.restaurantName  = RESTAURANT_NAME;
        req.reservationDate = TEST_DATE;

        Test.startTest();
        List<CheckRestaurantAvailabilityAction.AvailabilityResult> results =
            CheckRestaurantAvailabilityAction.checkAvailability(
                new List<CheckRestaurantAvailabilityAction.AvailabilityRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        CheckRestaurantAvailabilityAction.AvailabilityResult result = results[0];
        System.assertEquals(true,  result.isAvailable,    'Should be available');
        System.assertEquals(7,     result.availableSlots, 'Should have 7 slots available');
        System.assertEquals(10,    result.maxPartySize,   'Max party size should be 10');
        System.assertEquals(3,     result.bookedCount,    'Booked count should be 3');
        System.assert(result.message.contains('7'), 'Message should mention slot count');
        System.assert(result.message.contains(RESTAURANT_NAME), 'Message should contain restaurant name');
    }

    @IsTest
    static void testCheckAvailability_noSlots() {
        // Add reservations to fill the restaurant (need 7 more to hit Max_Party_Size=10)
        Account restaurant = [
            SELECT Id FROM Account
            WHERE RecordType.DeveloperName = 'Restaurant'
              AND Name = :RESTAURANT_NAME
            LIMIT 1
        ];
        Contact diner = [SELECT Id FROM Contact WHERE LastName = 'TestDiner' LIMIT 1];

        List<Reservation__c> extras = new List<Reservation__c>();
        for (Integer i = 0; i < 7; i++) {
            extras.add(new Reservation__c(
                Restaurant__c       = restaurant.Id,
                Diner__c            = diner.Id,
                Reservation_Date__c = TEST_DATE,
                Reservation_Time__c = Time.newInstance(19, 0, 0, 0),
                Party_Size__c       = 1,
                Status__c           = 'Confirmed'
            ));
        }
        insert extras;

        CheckRestaurantAvailabilityAction.AvailabilityRequest req =
            new CheckRestaurantAvailabilityAction.AvailabilityRequest();
        req.restaurantName  = RESTAURANT_NAME;
        req.reservationDate = TEST_DATE;

        Test.startTest();
        List<CheckRestaurantAvailabilityAction.AvailabilityResult> results =
            CheckRestaurantAvailabilityAction.checkAvailability(
                new List<CheckRestaurantAvailabilityAction.AvailabilityRequest>{ req }
            );
        Test.stopTest();

        CheckRestaurantAvailabilityAction.AvailabilityResult result = results[0];
        System.assertEquals(false, result.isAvailable,    'Should not be available when fully booked');
        System.assertEquals(0,     result.availableSlots, 'Available slots should be 0');
        System.assertEquals(10,    result.bookedCount,    'Booked count should be 10');
        System.assert(result.message.contains('no availability'), 'Message should indicate no availability');
    }

    @IsTest
    static void testCheckAvailability_notFound() {
        CheckRestaurantAvailabilityAction.AvailabilityRequest req =
            new CheckRestaurantAvailabilityAction.AvailabilityRequest();
        req.restaurantName  = 'ZZZNOMATCH';
        req.reservationDate = TEST_DATE;

        Test.startTest();
        Boolean threw = false;
        try {
            CheckRestaurantAvailabilityAction.checkAvailability(
                new List<CheckRestaurantAvailabilityAction.AvailabilityRequest>{ req }
            );
        } catch (AuraHandledException ex) {
            threw = true;
            System.assert(ex.getMessage() != null, 'Exception message should not be null');
        }
        Test.stopTest();

        System.assert(threw, 'AuraHandledException should have been thrown for missing restaurant');
    }
}