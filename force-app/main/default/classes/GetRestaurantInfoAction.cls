/**
 * GetRestaurantInfoAction
 * @InvocableMethod — looks up a restaurant Account by name and returns its details.
 * Uses a LIKE search so partial names (fuzzy match) resolve to results.
 * Throws AuraHandledException when no active restaurant matches the search term.
 */
public with sharing class GetRestaurantInfoAction {

    @InvocableMethod(label='Get Restaurant Info' description='Looks up a restaurant by name and returns its details')
    public static List<RestaurantDTO> getRestaurantInfo(List<String> restaurantNames) {
        String restaurantName = restaurantNames[0];
        String searchTerm = '%' + restaurantName + '%';

        List<Account> restaurants = [
            SELECT Name,
                   Cuisine_Type__c,
                   Operating_Hours__c,
                   Cancellation_Policy__c,
                   Price_Range__c,
                   Dress_Code__c,
                   Accessibility_Info__c,
                   Max_Party_Size__c,
                   Is_Active__c
            FROM Account
            WHERE RecordType.DeveloperName = 'Restaurant'
              AND Name LIKE :searchTerm
              AND Is_Active__c = true
            LIMIT 1
        ];

        if (restaurants.isEmpty()) {
            throw new AuraHandledException('Restaurant not found: ' + restaurantName);
        }

        Account restaurant = restaurants[0];
        RestaurantDTO dto = new RestaurantDTO();
        dto.name                = restaurant.Name;
        dto.cuisineType         = restaurant.Cuisine_Type__c;
        dto.operatingHours      = restaurant.Operating_Hours__c;
        dto.cancellationPolicy  = restaurant.Cancellation_Policy__c;
        dto.priceRange          = restaurant.Price_Range__c;
        dto.dressCode           = restaurant.Dress_Code__c;
        dto.accessibilityInfo   = restaurant.Accessibility_Info__c;
        dto.maxPartySize        = (restaurant.Max_Party_Size__c != null)
                                    ? Integer.valueOf(restaurant.Max_Party_Size__c)
                                    : null;
        dto.isActive            = restaurant.Is_Active__c;

        return new List<RestaurantDTO>{ dto };
    }

    public class RestaurantDTO {
        @InvocableVariable public String  name;
        @InvocableVariable public String  cuisineType;
        @InvocableVariable public String  operatingHours;
        @InvocableVariable public String  cancellationPolicy;
        @InvocableVariable public String  priceRange;
        @InvocableVariable public String  dressCode;
        @InvocableVariable public String  accessibilityInfo;
        @InvocableVariable public Integer maxPartySize;
        @InvocableVariable public Boolean isActive;
    }
}