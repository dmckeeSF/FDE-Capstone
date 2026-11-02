public with sharing class GetRestaurantsByLocationAction {

    public class Request {
        @InvocableVariable(label='City' required=true)
        public String city;

        @InvocableVariable(label='State')
        public String state;
    }

    public class Response {
        @InvocableVariable(label='Restaurant List')
        public String restaurantList;

        @InvocableVariable(label='Restaurant Count')
        public Integer restaurantCount;

        @InvocableVariable(label='City Searched')
        public String citySearched;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Get Restaurants By Location'
        description='Returns all active TableTopia restaurants in a given city, queried from Account shipping address'
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

        if (String.isBlank(req.city)) {
            res.errorMessage = 'City is required.';
            return res;
        }

        // Strip "City, State" format the LLM sometimes passes (e.g. "Bellevue, WA")
        String cityRaw  = req.city.trim();
        String cityTrim = cityRaw.contains(',') ? cityRaw.split(',')[0].trim() : cityRaw;
        String cityLike = '%' + cityTrim + '%';
        res.citySearched = cityTrim;

        List<Account> restaurants;
        if (String.isNotBlank(req.state)) {
            String stateTrim = req.state.trim().split(',')[0].trim();
            String stateLike = '%' + stateTrim + '%';
            restaurants = [
                SELECT Name, Cuisine_Type__c, Price_Range__c,
                       Accessibility_Info__c, Star_Rating__c, ShippingCity, ShippingState
                FROM Account
                WHERE RecordType.DeveloperName = 'Restaurant'
                  AND Is_Active__c = true
                  AND ShippingCity LIKE :cityLike
                  AND ShippingState LIKE :stateLike
                ORDER BY Star_Rating__c DESC NULLS LAST, Name ASC
            ];
        } else {
            restaurants = [
                SELECT Name, Cuisine_Type__c, Price_Range__c,
                       Accessibility_Info__c, Star_Rating__c, ShippingCity, ShippingState
                FROM Account
                WHERE RecordType.DeveloperName = 'Restaurant'
                  AND Is_Active__c = true
                  AND ShippingCity LIKE :cityLike
                ORDER BY Star_Rating__c DESC NULLS LAST, Name ASC
            ];
        }

        res.restaurantCount = restaurants.size();

        if (restaurants.isEmpty()) {
            res.isSuccess    = true;
            res.restaurantList = 'No TableTopia restaurants found in ' + cityTrim + '.';
            return res;
        }

        List<String> lines = new List<String>();
        for (Account a : restaurants) {
            String stars = a.Star_Rating__c != null ? ' (★' + String.valueOf(Integer.valueOf(a.Star_Rating__c)) + '/5)' : '';
            String line = a.Name + stars;
            if (String.isNotBlank(a.Cuisine_Type__c)) line += ' — ' + a.Cuisine_Type__c;
            if (String.isNotBlank(a.Price_Range__c))  line += ', ' + a.Price_Range__c;
            if (String.isNotBlank(a.Accessibility_Info__c)) line += '. ' + a.Accessibility_Info__c;
            lines.add(line);
        }

        res.restaurantList = String.join(lines, '\n');
        res.isSuccess      = true;
        return res;
    }
}