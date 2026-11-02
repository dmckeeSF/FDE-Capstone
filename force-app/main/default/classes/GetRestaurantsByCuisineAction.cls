public without sharing class GetRestaurantsByCuisineAction {

    public class Request {
        @InvocableVariable(label='Cuisine Type' required=true)
        public String cuisineType;
    }

    public class Response {
        @InvocableVariable(label='Restaurant List')
        public String restaurantList;

        @InvocableVariable(label='Restaurant Count')
        public Integer restaurantCount;

        @InvocableVariable(label='Cuisine Searched')
        public String cuisineSearched;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Get Restaurants By Cuisine'
        description='Returns all active SeatMe restaurants matching a cuisine type'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) {
            results.add(search(req));
        }
        return results;
    }

    private static Response search(Request req) {
        Response res = new Response();
        res.isSuccess = false;

        if (String.isBlank(req.cuisineType)) {
            res.errorMessage = 'Cuisine type is required.';
            return res;
        }

        String term = '%' + req.cuisineType.trim() + '%';
        res.cuisineSearched = req.cuisineType.trim();

        List<Account> restaurants = [
            SELECT Name, Cuisine_Type__c, Price_Range__c,
                   Accessibility_Info__c, ShippingCity, ShippingState
            FROM Account
            WHERE RecordType.DeveloperName = 'Restaurant'
              AND Is_Active__c = true
              AND Cuisine_Type__c LIKE :term
            ORDER BY Name
        ];

        res.restaurantCount = restaurants.size();

        if (restaurants.isEmpty()) {
            res.isSuccess      = true;
            res.restaurantList = 'No SeatMe restaurants found for ' + req.cuisineType.trim() + ' cuisine.';
            return res;
        }

        List<String> lines = new List<String>();
        for (Account a : restaurants) {
            String line = a.Name;
            if (String.isNotBlank(a.Cuisine_Type__c)) line += ' — ' + a.Cuisine_Type__c;
            if (String.isNotBlank(a.Price_Range__c))  line += ', ' + a.Price_Range__c;
            if (String.isNotBlank(a.ShippingCity))    line += ' (' + a.ShippingCity + (String.isNotBlank(a.ShippingState) ? ', ' + a.ShippingState : '') + ')';
            lines.add(line);
        }

        res.restaurantList = String.join(lines, '\n');
        res.isSuccess      = true;
        return res;
    }
}
