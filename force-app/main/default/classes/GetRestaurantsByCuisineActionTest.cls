@IsTest
private class GetRestaurantsByCuisineActionTest {

    @TestSetup
    static void setup() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];

        insert new List<Account>{
            new Account(
                Name            = 'Test Trattoria Roma',
                RecordTypeId    = rt.Id,
                Is_Active__c    = true,
                ShippingCity    = 'Seattle',
                ShippingState   = 'WA',
                Cuisine_Type__c = 'Italian',
                Price_Range__c  = '$$$'
            ),
            new Account(
                Name            = 'Test Pasta Palace',
                RecordTypeId    = rt.Id,
                Is_Active__c    = true,
                ShippingCity    = 'Bellevue',
                ShippingState   = 'WA',
                Cuisine_Type__c = 'Italian',
                Price_Range__c  = '$$'
            ),
            new Account(
                Name            = 'Test Sakura Sushi',
                RecordTypeId    = rt.Id,
                Is_Active__c    = true,
                ShippingCity    = 'Seattle',
                ShippingState   = 'WA',
                Cuisine_Type__c = 'Japanese',
                Price_Range__c  = '$$'
            ),
            new Account(
                Name            = 'Inactive Italian Place',
                RecordTypeId    = rt.Id,
                Is_Active__c    = false,
                ShippingCity    = 'Seattle',
                ShippingState   = 'WA',
                Cuisine_Type__c = 'Italian'
            )
        };
    }

    @IsTest
    static void testCuisineReturnsMultipleResults() {
        GetRestaurantsByCuisineAction.Request req = new GetRestaurantsByCuisineAction.Request();
        req.cuisineType = 'Italian';

        Test.startTest();
        List<GetRestaurantsByCuisineAction.Response> results =
            GetRestaurantsByCuisineAction.execute(
                new List<GetRestaurantsByCuisineAction.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        GetRestaurantsByCuisineAction.Response res = results[0];
        System.assert(res.isSuccess, 'Expected success');
        System.assertEquals(2, res.restaurantCount, 'Expected 2 active Italian restaurants');
        System.assert(res.restaurantList.contains('Test Trattoria Roma'), 'Expected first restaurant');
        System.assert(res.restaurantList.contains('Test Pasta Palace'), 'Expected second restaurant');
        System.assertEquals('Italian', res.cuisineSearched);
    }

    @IsTest
    static void testInactiveExcluded() {
        GetRestaurantsByCuisineAction.Request req = new GetRestaurantsByCuisineAction.Request();
        req.cuisineType = 'Italian';

        Test.startTest();
        List<GetRestaurantsByCuisineAction.Response> results =
            GetRestaurantsByCuisineAction.execute(
                new List<GetRestaurantsByCuisineAction.Request>{ req }
            );
        Test.stopTest();

        System.assert(!results[0].restaurantList.contains('Inactive'), 'Inactive restaurant must not appear');
    }

    @IsTest
    static void testNoMatchReturnsEmptyMessage() {
        GetRestaurantsByCuisineAction.Request req = new GetRestaurantsByCuisineAction.Request();
        req.cuisineType = 'Ethiopian';

        Test.startTest();
        List<GetRestaurantsByCuisineAction.Response> results =
            GetRestaurantsByCuisineAction.execute(
                new List<GetRestaurantsByCuisineAction.Request>{ req }
            );
        Test.stopTest();

        GetRestaurantsByCuisineAction.Response res = results[0];
        System.assert(res.isSuccess, 'No-match should still succeed');
        System.assertEquals(0, res.restaurantCount);
        System.assert(res.restaurantList.contains('No SeatMe restaurants found'), 'Expected no-results message');
    }

    @IsTest
    static void testBlankCuisineReturnsError() {
        GetRestaurantsByCuisineAction.Request req = new GetRestaurantsByCuisineAction.Request();
        req.cuisineType = '';

        Test.startTest();
        List<GetRestaurantsByCuisineAction.Response> results =
            GetRestaurantsByCuisineAction.execute(
                new List<GetRestaurantsByCuisineAction.Request>{ req }
            );
        Test.stopTest();

        System.assert(!results[0].isSuccess, 'Blank cuisine should not succeed');
        System.assert(String.isNotBlank(results[0].errorMessage));
    }

    @IsTest
    static void testPartialMatchWorks() {
        GetRestaurantsByCuisineAction.Request req = new GetRestaurantsByCuisineAction.Request();
        req.cuisineType = 'Japan';

        Test.startTest();
        List<GetRestaurantsByCuisineAction.Response> results =
            GetRestaurantsByCuisineAction.execute(
                new List<GetRestaurantsByCuisineAction.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results[0].restaurantCount, 'Partial cuisine match should find Japanese');
        System.assert(results[0].restaurantList.contains('Test Sakura Sushi'));
    }

    @IsTest
    static void testCaseInsensitiveMatch() {
        GetRestaurantsByCuisineAction.Request req = new GetRestaurantsByCuisineAction.Request();
        req.cuisineType = 'italian';

        Test.startTest();
        List<GetRestaurantsByCuisineAction.Response> results =
            GetRestaurantsByCuisineAction.execute(
                new List<GetRestaurantsByCuisineAction.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(2, results[0].restaurantCount, 'Lowercase cuisine should still match');
    }
}
