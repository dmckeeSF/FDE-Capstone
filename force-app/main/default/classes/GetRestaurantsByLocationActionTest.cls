@IsTest
private class GetRestaurantsByLocationActionTest {

    @TestSetup
    static void setup() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];

        insert new List<Account>{
            new Account(
                Name            = 'Test Bistro Bellevue',
                RecordTypeId    = rt.Id,
                Is_Active__c    = true,
                ShippingCity    = 'Bellevue',
                ShippingState   = 'WA',
                Cuisine_Type__c = 'American',
                Price_Range__c  = '$$'
            ),
            new Account(
                Name            = 'Test Noodle House Bellevue',
                RecordTypeId    = rt.Id,
                Is_Active__c    = true,
                ShippingCity    = 'Bellevue',
                ShippingState   = 'WA',
                Cuisine_Type__c = 'Asian Fusion',
                Price_Range__c  = '$'
            ),
            new Account(
                Name            = 'Test Seattle Spot',
                RecordTypeId    = rt.Id,
                Is_Active__c    = true,
                ShippingCity    = 'Seattle',
                ShippingState   = 'WA',
                Cuisine_Type__c = 'Seafood',
                Price_Range__c  = '$$$'
            ),
            new Account(
                Name            = 'Inactive Bellevue Place',
                RecordTypeId    = rt.Id,
                Is_Active__c    = false,
                ShippingCity    = 'Bellevue',
                ShippingState   = 'WA'
            )
        };
    }

    @IsTest
    static void testCityReturnsMultipleResults() {
        GetRestaurantsByLocationAction.Request req = new GetRestaurantsByLocationAction.Request();
        req.city = 'Bellevue';

        Test.startTest();
        List<GetRestaurantsByLocationAction.Response> results =
            GetRestaurantsByLocationAction.execute(
                new List<GetRestaurantsByLocationAction.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        GetRestaurantsByLocationAction.Response res = results[0];
        System.assert(res.isSuccess, 'Expected success');
        System.assertEquals(2, res.restaurantCount, 'Expected 2 active Bellevue restaurants');
        System.assert(res.restaurantList.contains('Test Bistro Bellevue'), 'Expected first restaurant in list');
        System.assert(res.restaurantList.contains('Test Noodle House Bellevue'), 'Expected second restaurant in list');
        System.assertEquals('Bellevue', res.citySearched);
    }

    @IsTest
    static void testCityWithStateFilter() {
        GetRestaurantsByLocationAction.Request req = new GetRestaurantsByLocationAction.Request();
        req.city  = 'Bellevue';
        req.state = 'WA';

        Test.startTest();
        List<GetRestaurantsByLocationAction.Response> results =
            GetRestaurantsByLocationAction.execute(
                new List<GetRestaurantsByLocationAction.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(2, results[0].restaurantCount);
    }

    @IsTest
    static void testInactiveRestaurantsExcluded() {
        // Inactive Bellevue Place must not appear even though it's in Bellevue
        GetRestaurantsByLocationAction.Request req = new GetRestaurantsByLocationAction.Request();
        req.city = 'Bellevue';

        Test.startTest();
        List<GetRestaurantsByLocationAction.Response> results =
            GetRestaurantsByLocationAction.execute(
                new List<GetRestaurantsByLocationAction.Request>{ req }
            );
        Test.stopTest();

        System.assert(!results[0].restaurantList.contains('Inactive'), 'Inactive restaurant must not appear');
    }

    @IsTest
    static void testCityWithNoResults() {
        GetRestaurantsByLocationAction.Request req = new GetRestaurantsByLocationAction.Request();
        req.city = 'Portland';

        Test.startTest();
        List<GetRestaurantsByLocationAction.Response> results =
            GetRestaurantsByLocationAction.execute(
                new List<GetRestaurantsByLocationAction.Request>{ req }
            );
        Test.stopTest();

        GetRestaurantsByLocationAction.Response res = results[0];
        System.assert(res.isSuccess, 'Empty results should still succeed');
        System.assertEquals(0, res.restaurantCount);
        System.assert(res.restaurantList.contains('No TableTopia restaurants found'), 'Expected no-results message');
    }

    @IsTest
    static void testBlankCityReturnsError() {
        GetRestaurantsByLocationAction.Request req = new GetRestaurantsByLocationAction.Request();
        req.city = '';

        Test.startTest();
        List<GetRestaurantsByLocationAction.Response> results =
            GetRestaurantsByLocationAction.execute(
                new List<GetRestaurantsByLocationAction.Request>{ req }
            );
        Test.stopTest();

        System.assert(!results[0].isSuccess, 'Blank city should not succeed');
        System.assert(String.isNotBlank(results[0].errorMessage));
    }

    @IsTest
    static void testDifferentCity() {
        GetRestaurantsByLocationAction.Request req = new GetRestaurantsByLocationAction.Request();
        req.city = 'Seattle';

        Test.startTest();
        List<GetRestaurantsByLocationAction.Response> results =
            GetRestaurantsByLocationAction.execute(
                new List<GetRestaurantsByLocationAction.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results[0].restaurantCount);
        System.assert(results[0].restaurantList.contains('Test Seattle Spot'));
    }
}
