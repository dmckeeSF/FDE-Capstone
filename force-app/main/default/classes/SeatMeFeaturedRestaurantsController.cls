public without sharing class SeatMeFeaturedRestaurantsController {

    @AuraEnabled(cacheable=true)
    public static List<RestaurantCard> getFeaturedRestaurants() {
        List<RestaurantCard> cards = new List<RestaurantCard>();
        for (Account a : [
            SELECT Id, Name, Cuisine_Type__c, Operating_Hours__c, Price_Range__c
            FROM Account
            WHERE RecordType.DeveloperName = 'Restaurant'
              AND Is_Active__c = true
            ORDER BY Name
            LIMIT 6
        ]) {
            RestaurantCard card = new RestaurantCard();
            card.id           = a.Id;
            card.name         = a.Name;
            card.cuisineType  = a.Cuisine_Type__c;
            card.hours        = a.Operating_Hours__c;
            card.priceRange   = a.Price_Range__c;
            cards.add(card);
        }
        return cards;
    }

    public class RestaurantCard {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String cuisineType;
        @AuraEnabled public String hours;
        @AuraEnabled public String priceRange;
    }
}
