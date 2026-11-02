@isTest
private class SearchRestaurantsActionTest {

    private static Id restaurantRecordTypeId {
        get {
            if (restaurantRecordTypeId == null) {
                restaurantRecordTypeId = Schema.SObjectType.Account
                    .getRecordTypeInfosByDeveloperName()
                    .get('Restaurant').getRecordTypeId();
            }
            return restaurantRecordTypeId;
        }
        set;
    }

    private static void insertRestaurants() {
        List<Account> restaurants = new List<Account>{
            new Account(
                Name = 'Test Bistro',
                RecordTypeId = restaurantRecordTypeId,
                Is_Active__c = true,
                Cuisine_Type__c = 'French',
                Price_Range__c = '$$$',
                Dress_Code__c = 'Smart Casual',
                Max_Party_Size__c = 10,
                Star_Rating__c = 5,
                ShippingCity = 'Seattle',
                ShippingState = 'WA'
            ),
            new Account(
                Name = 'Test Tacos',
                RecordTypeId = restaurantRecordTypeId,
                Is_Active__c = true,
                Cuisine_Type__c = 'Mexican',
                Price_Range__c = '$',
                Dress_Code__c = 'Casual',
                Max_Party_Size__c = 20,
                Star_Rating__c = 3,
                ShippingCity = 'Bellevue',
                ShippingState = 'WA'
            ),
            new Account(
                Name = 'Test Sushi',
                RecordTypeId = restaurantRecordTypeId,
                Is_Active__c = true,
                Cuisine_Type__c = 'Japanese',
                Price_Range__c = '$$',
                Dress_Code__c = 'Casual',
                Max_Party_Size__c = 8,
                Star_Rating__c = 4,
                ShippingCity = 'Seattle',
                ShippingState = 'WA'
            )
        };
        insert restaurants;
    }

    @isTest
    static void testSearchByCity() {
        insertRestaurants();
        SearchRestaurantsAction.SearchRequest req = new SearchRestaurantsAction.SearchRequest();
        req.city = 'Seattle';

        Test.startTest();
        List<SearchRestaurantsAction.SearchResponse> results =
            SearchRestaurantsAction.execute(new List<SearchRestaurantsAction.SearchRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals(2, results[0].restaurantCount);
        System.assert(results[0].restaurantList.contains('Test Bistro'), 'Should include Test Bistro');
        System.assert(results[0].restaurantList.indexOf('Test Bistro') < results[0].restaurantList.indexOf('Test Sushi'),
            'Higher rated restaurant should appear first');
    }

    @isTest
    static void testSearchByCuisineAndPriceRange() {
        insertRestaurants();
        SearchRestaurantsAction.SearchRequest req = new SearchRestaurantsAction.SearchRequest();
        req.cuisineType = 'Mexican';
        req.priceRange = '$';

        Test.startTest();
        List<SearchRestaurantsAction.SearchResponse> results =
            SearchRestaurantsAction.execute(new List<SearchRestaurantsAction.SearchRequest>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals(1, results[0].restaurantCount);
        System.assert(results[0].restaurantList.contains('Test Tacos'));
    }

    @isTest
    static void testSearchByMinPartySize() {
        insertRestaurants();
        SearchRestaurantsAction.SearchRequest req = new SearchRestaurantsAction.SearchRequest();
        req.minPartySize = 15;

        Test.startTest();
        List<SearchRestaurantsAction.SearchResponse> results =
            SearchRestaurantsAction.execute(new List<SearchRestaurantsAction.SearchRequest>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals(1, results[0].restaurantCount);
        System.assert(results[0].restaurantList.contains('Test Tacos'));
    }

    @isTest
    static void testNoResults() {
        insertRestaurants();
        SearchRestaurantsAction.SearchRequest req = new SearchRestaurantsAction.SearchRequest();
        req.city = 'Portland';

        Test.startTest();
        List<SearchRestaurantsAction.SearchResponse> results =
            SearchRestaurantsAction.execute(new List<SearchRestaurantsAction.SearchRequest>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals(0, results[0].restaurantCount);
        System.assert(results[0].restaurantList.contains('No restaurants found'));
    }
}
