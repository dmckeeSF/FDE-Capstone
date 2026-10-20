/**
 * GetRestaurantInfoAction
 * @InvocableMethod — looks up a restaurant Account by name and returns its details.
 * Uses a LIKE search so partial names (fuzzy match) resolve to results.
 * Throws AuraHandledException when no active restaurant matches the search term.
 */
public with sharing class GetRestaurantInfoAction {

    @InvocableMethod(label='Get Restaurant Info' description='Looks up a restaurant by name and returns its details')
    public static List<RestaurantDTO> getRestaurantInfo(List<String> restaurantNames) {
        // Build LIKE patterns and collect results in one SOQL pass
        // Because each name may use a LIKE search, query all restaurants once
        // and match each input name in Apex to avoid N queries.
        List<Account> allRestaurants = [
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
              AND Is_Active__c = true
            ORDER BY Name
        ];

        List<RestaurantDTO> results = new List<RestaurantDTO>();
        for (String restaurantName : restaurantNames) {
            String term = restaurantName.toLowerCase();
            Account match = null;
            for (Account a : allRestaurants) {
                if (a.Name.toLowerCase().contains(term)) {
                    match = a;
                    break;
                }
            }
            if (match == null) {
                throw new AuraHandledException('Restaurant not found: ' + restaurantName);
            }
            RestaurantDTO dto        = new RestaurantDTO();
            dto.name                 = match.Name;
            dto.cuisineType          = match.Cuisine_Type__c;
            dto.operatingHours       = match.Operating_Hours__c;
            dto.cancellationPolicy   = match.Cancellation_Policy__c;
            dto.priceRange           = match.Price_Range__c;
            dto.dressCode            = match.Dress_Code__c;
            dto.accessibilityInfo    = match.Accessibility_Info__c;
            dto.maxPartySize         = (match.Max_Party_Size__c != null)
                                         ? Integer.valueOf(match.Max_Party_Size__c)
                                         : null;
            dto.isActive             = match.Is_Active__c;
            results.add(dto);
        }
        return results;
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