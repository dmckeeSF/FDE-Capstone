public with sharing class GetLoyaltyTierAction {

    public class Request {
        @InvocableVariable(label='Contact Email' required=true)
        public String contactEmail;
    }

    public class Response {
        @InvocableVariable(label='Loyalty Tier')
        public String loyaltyTier;

        @InvocableVariable(label='Member ID')
        public String memberId;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Get Loyalty Tier'
        description='Retrieves the diner loyalty tier from the external loyalty program API'
        callout=true
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) {
            results.add(lookup(req));
        }
        return results;
    }

    private static Response lookup(Request req) {
        Response res = new Response();
        res.isSuccess   = false;
        res.loyaltyTier = 'Standard';

        if (String.isBlank(req.contactEmail)) {
            res.errorMessage = 'Contact email is required.';
            return res;
        }

        try {
            List<Loyalty_API_Settings__mdt> settings = [
                SELECT API_Key__c FROM Loyalty_API_Settings__mdt
                WHERE DeveloperName = 'Default' LIMIT 1
            ];
            String apiKey = settings.isEmpty() ? '' : settings[0].API_Key__c;

            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint('callout:Loyalty_Program_API');
            httpReq.setMethod('GET');
            httpReq.setTimeout(10000);
            if (String.isNotBlank(apiKey)) {
                httpReq.setHeader('x-api-key', apiKey);
            }

            HttpResponse httpRes = new Http().send(httpReq);

            if (httpRes.getStatusCode() != 200) {
                res.errorMessage = 'Loyalty API returned HTTP ' + httpRes.getStatusCode();
                return res;
            }

            List<Object> records = (List<Object>) JSON.deserializeUntyped(httpRes.getBody());
            String emailLower = req.contactEmail.toLowerCase().trim();

            for (Object obj : records) {
                Map<String, Object> record = (Map<String, Object>) obj;
                String recordEmail = String.valueOf(record.get('email')).toLowerCase().trim();
                if (recordEmail == emailLower) {
                    res.loyaltyTier = String.valueOf(record.get('tier'));
                    res.memberId    = String.valueOf(record.get('memberId'));
                    res.isSuccess   = true;
                    return res;
                }
            }

            res.errorMessage = 'Diner not found in loyalty program.';
            return res;

        } catch (Exception e) {
            res.errorMessage = 'Loyalty lookup failed: ' + e.getMessage();
            return res;
        }
    }
}
