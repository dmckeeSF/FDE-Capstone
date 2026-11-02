@IsTest
private class SeatMeFeaturedRestaurantsControllerTest {

    @TestSetup
    static void setup() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];
        List<Account> restaurants = new List<Account>{
            new Account(Name = 'Alpha Kitchen',  RecordTypeId = rt.Id, Is_Active__c = true),
            new Account(Name = 'Beta Bistro',    RecordTypeId = rt.Id, Is_Active__c = true),
            new Account(Name = 'Inactive Place', RecordTypeId = rt.Id, Is_Active__c = false)
        };
        insert restaurants;
    }

    @IsTest
    static void testReturnsFeaturedRestaurants() {
        Test.startTest();
        List<SeatMeFeaturedRestaurantsController.RestaurantCard> cards =
            SeatMeFeaturedRestaurantsController.getFeaturedRestaurants();
        Test.stopTest();

        System.assert(cards.size() >= 2, 'Expected at least 2 active restaurants');
        for (SeatMeFeaturedRestaurantsController.RestaurantCard card : cards) {
            System.assertNotEquals(null, card.id);
            System.assertNotEquals(null, card.name);
        }
    }

    @IsTest
    static void testExcludesInactiveRestaurants() {
        Test.startTest();
        List<SeatMeFeaturedRestaurantsController.RestaurantCard> cards =
            SeatMeFeaturedRestaurantsController.getFeaturedRestaurants();
        Test.stopTest();

        for (SeatMeFeaturedRestaurantsController.RestaurantCard card : cards) {
            System.assertNotEquals('Inactive Place', card.name, 'Inactive restaurant should be excluded');
        }
    }

    @IsTest
    static void testReturnsAtMostSix() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];
        List<Account> extra = new List<Account>();
        for (Integer i = 3; i <= 8; i++) {
            extra.add(new Account(Name = 'Restaurant ' + i, RecordTypeId = rt.Id, Is_Active__c = true));
        }
        insert extra;

        Test.startTest();
        List<SeatMeFeaturedRestaurantsController.RestaurantCard> cards =
            SeatMeFeaturedRestaurantsController.getFeaturedRestaurants();
        Test.stopTest();

        System.assert(cards.size() <= 6, 'Should return at most 6 restaurants');
    }
}
