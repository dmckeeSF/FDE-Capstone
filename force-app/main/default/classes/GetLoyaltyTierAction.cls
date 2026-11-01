public without sharing class GetLoyaltyTierAction {

    private static final String DMO = 'LPR_LoyaltyMember_81F1B696__dlm';

    public class Request {
        @InvocableVariable(label='Contact Email' required=false)
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
        description='Retrieves the diner loyalty tier from the Data Cloud loyalty DMO'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) {
            results.add(lookup(req));
        }
        return results;
    }

    // Populated in tests to avoid live DMO dependency
    @TestVisible
    private static Map<String, Map<String, String>> dmoTestData = null;

    // Set true in tests to exercise the catch block
    @TestVisible
    private static Boolean forceException = false;

    private static Response lookup(Request req) {
        Response res = new Response();
        res.isSuccess   = false;
        res.loyaltyTier = 'Standard';

        if (String.isBlank(req.contactEmail)) {
            res.errorMessage = 'Contact email is required.';
            return res;
        }

        try {
            if (forceException) {
                throw new System.MathException('forced test exception');
            }

            String emailLower = req.contactEmail.toLowerCase().trim();
            String tier;
            String memberId;

            if (dmoTestData != null) {
                if (dmoTestData.containsKey(emailLower)) {
                    tier     = dmoTestData.get(emailLower).get('tier');
                    memberId = dmoTestData.get(emailLower).get('memberId');
                }
                // Not found → Standard fallback (isSuccess stays true)
            } else {
                List<SObject> records = Database.query(
                    'SELECT tier__c, member_id__c FROM ' + DMO +
                    ' WHERE email__c = :emailLower LIMIT 1'
                );
                if (!records.isEmpty()) {
                    tier     = (String) records[0].get('tier__c');
                    memberId = (String) records[0].get('member_id__c');
                }
                // Not found → Standard fallback (isSuccess stays true)
            }

            if (String.isNotBlank(tier)) {
                res.loyaltyTier = tier;
                res.memberId    = memberId;
                res.isSuccess   = true;
            } else {
                res.errorMessage = 'Loyalty tier not found for this email.';
            }
            return res;

        } catch (Exception e) {
            res.errorMessage = 'Loyalty lookup failed: ' + e.getMessage();
            return res;
        }
    }
}