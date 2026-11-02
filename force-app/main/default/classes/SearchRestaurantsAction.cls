public without sharing class SearchRestaurantsAction {

    @InvocableMethod(label='Search Restaurants' description='Multi-criteria restaurant search — city, cuisine, price range, dress code, party size — sorted by star rating descending')
    public static List<SearchResponse> execute(List<SearchRequest> requests) {
        List<SearchResponse> results = new List<SearchResponse>();
        for (SearchRequest req : requests) {
            results.add(search(req));
        }
        return results;
    }

    private static SearchResponse search(SearchRequest req) {
        SearchResponse res = new SearchResponse();

        List<Account> all = [
            SELECT Name, Cuisine_Type__c, Price_Range__c, Dress_Code__c,
                   Max_Party_Size__c, Star_Rating__c, Accessibility_Info__c,
                   ShippingCity, ShippingState
            FROM Account
            WHERE RecordType.DeveloperName = 'Restaurant'
              AND Is_Active__c = true
            ORDER BY Star_Rating__c DESC NULLS LAST, Name ASC
        ];

        List<Account> filtered = new List<Account>();
        for (Account a : all) {
            if (String.isNotBlank(req.city)) {
                String city = req.city.contains(',') ? req.city.split(',')[0].trim() : req.city.trim();
                if (a.ShippingCity == null || !a.ShippingCity.toLowerCase().contains(city.toLowerCase())) continue;
            }
            if (String.isNotBlank(req.cuisineType)) {
                if (a.Cuisine_Type__c == null || !a.Cuisine_Type__c.toLowerCase().contains(req.cuisineType.toLowerCase())) continue;
            }
            if (String.isNotBlank(req.priceRange)) {
                if (a.Price_Range__c == null || !a.Price_Range__c.equalsIgnoreCase(req.priceRange.trim())) continue;
            }
            if (String.isNotBlank(req.dressCode)) {
                if (a.Dress_Code__c == null || !a.Dress_Code__c.toLowerCase().contains(req.dressCode.toLowerCase())) continue;
            }
            if (req.minPartySize != null && req.minPartySize > 0) {
                if (a.Max_Party_Size__c == null || a.Max_Party_Size__c < req.minPartySize) continue;
            }
            filtered.add(a);
        }

        res.restaurantCount = filtered.size();

        if (filtered.isEmpty()) {
            res.isSuccess      = true;
            res.restaurantList = buildNoResultsMessage(req);
            return res;
        }

        List<String> lines = new List<String>();
        for (Account a : filtered) {
            String stars = a.Star_Rating__c != null ? '★ ' + String.valueOf(Integer.valueOf(a.Star_Rating__c)) + '/5' : '';
            String line  = a.Name;
            if (String.isNotBlank(stars))              line += ' (' + stars + ')';
            if (String.isNotBlank(a.Cuisine_Type__c))  line += ' — ' + a.Cuisine_Type__c;
            if (String.isNotBlank(a.Price_Range__c))   line += ', ' + a.Price_Range__c;
            if (String.isNotBlank(a.Dress_Code__c))    line += ', ' + a.Dress_Code__c;
            if (a.Max_Party_Size__c != null)            line += ', up to ' + Integer.valueOf(a.Max_Party_Size__c) + ' guests';
            if (String.isNotBlank(a.ShippingCity))      line += ' (' + a.ShippingCity + (String.isNotBlank(a.ShippingState) ? ', ' + a.ShippingState : '') + ')';
            lines.add(line);
        }

        res.restaurantList = String.join(lines, '\n');
        res.isSuccess      = true;
        return res;
    }

    private static String buildNoResultsMessage(SearchRequest req) {
        List<String> criteria = new List<String>();
        if (String.isNotBlank(req.city))        criteria.add('city: ' + req.city);
        if (String.isNotBlank(req.cuisineType)) criteria.add('cuisine: ' + req.cuisineType);
        if (String.isNotBlank(req.priceRange))  criteria.add('price: ' + req.priceRange);
        if (String.isNotBlank(req.dressCode))   criteria.add('dress code: ' + req.dressCode);
        if (req.minPartySize != null)            criteria.add('party size: ' + req.minPartySize + '+');
        return 'No restaurants found matching: ' + String.join(criteria, ', ') + '.';
    }

    public class SearchRequest {
        @InvocableVariable(label='City')          public String  city;
        @InvocableVariable(label='Cuisine Type')  public String  cuisineType;
        @InvocableVariable(label='Price Range')   public String  priceRange;
        @InvocableVariable(label='Dress Code')    public String  dressCode;
        @InvocableVariable(label='Min Party Size') public Integer minPartySize;
    }

    public class SearchResponse {
        @InvocableVariable public String  restaurantList;
        @InvocableVariable public Integer restaurantCount;
        @InvocableVariable public Boolean isSuccess;
        @InvocableVariable public String  errorMessage;
    }
}
