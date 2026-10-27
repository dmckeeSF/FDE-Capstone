@IsTest
private class GetLoyaltyTierActionTest {

    private class LoyaltyMock implements HttpCalloutMock {
        private Integer statusCode;
        private String  body;

        LoyaltyMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body       = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    private static final String MOCK_BODY =
        '[' +
            '{"email":"sofia.rodriguez@example.com","tier":"Platinum","memberId":"LYL-00123"},' +
            '{"email":"test.diner@tabletopia.com","tier":"Gold","memberId":"LYL-00456"}' +
        ']';

    @IsTest
    static void testPlatinumTierReturned() {
        Test.setMock(HttpCalloutMock.class, new LoyaltyMock(200, MOCK_BODY));

        GetLoyaltyTierAction.Request req = new GetLoyaltyTierAction.Request();
        req.contactEmail = 'sofia.rodriguez@example.com';

        Test.startTest();
        List<GetLoyaltyTierAction.Response> results = GetLoyaltyTierAction.execute(
            new List<GetLoyaltyTierAction.Request>{ req }
        );
        Test.stopTest();

        GetLoyaltyTierAction.Response res = results[0];
        System.assertEquals('Platinum', res.loyaltyTier, 'Expected Platinum for Sofia');
        System.assertEquals('LYL-00123', res.memberId);
        System.assert(res.isSuccess, 'Expected isSuccess=true');
    }

    @IsTest
    static void testGoldTierReturned() {
        Test.setMock(HttpCalloutMock.class, new LoyaltyMock(200, MOCK_BODY));

        GetLoyaltyTierAction.Request req = new GetLoyaltyTierAction.Request();
        req.contactEmail = 'test.diner@tabletopia.com';

        Test.startTest();
        List<GetLoyaltyTierAction.Response> results = GetLoyaltyTierAction.execute(
            new List<GetLoyaltyTierAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals('Gold', results[0].loyaltyTier);
        System.assert(results[0].isSuccess);
    }

    @IsTest
    static void testUnknownEmailReturnsStandard() {
        Test.setMock(HttpCalloutMock.class, new LoyaltyMock(200, MOCK_BODY));

        GetLoyaltyTierAction.Request req = new GetLoyaltyTierAction.Request();
        req.contactEmail = 'unknown@nowhere.com';

        Test.startTest();
        List<GetLoyaltyTierAction.Response> results = GetLoyaltyTierAction.execute(
            new List<GetLoyaltyTierAction.Request>{ req }
        );
        Test.stopTest();

        GetLoyaltyTierAction.Response res = results[0];
        System.assertEquals('Standard', res.loyaltyTier, 'Unknown email should default to Standard');
        System.assert(!res.isSuccess);
        System.assert(String.isNotBlank(res.errorMessage));
    }

    @IsTest
    static void testApiErrorReturnsStandard() {
        Test.setMock(HttpCalloutMock.class, new LoyaltyMock(500, 'Internal Server Error'));

        GetLoyaltyTierAction.Request req = new GetLoyaltyTierAction.Request();
        req.contactEmail = 'sofia.rodriguez@example.com';

        Test.startTest();
        List<GetLoyaltyTierAction.Response> results = GetLoyaltyTierAction.execute(
            new List<GetLoyaltyTierAction.Request>{ req }
        );
        Test.stopTest();

        GetLoyaltyTierAction.Response res = results[0];
        System.assertEquals('Standard', res.loyaltyTier);
        System.assert(!res.isSuccess);
        System.assert(String.isNotBlank(res.errorMessage));
    }

    @IsTest
    static void testBlankEmailReturnsError() {
        GetLoyaltyTierAction.Request req = new GetLoyaltyTierAction.Request();
        req.contactEmail = '';

        Test.startTest();
        List<GetLoyaltyTierAction.Response> results = GetLoyaltyTierAction.execute(
            new List<GetLoyaltyTierAction.Request>{ req }
        );
        Test.stopTest();

        GetLoyaltyTierAction.Response res = results[0];
        System.assertEquals('Standard', res.loyaltyTier);
        System.assert(!res.isSuccess);
        System.assert(String.isNotBlank(res.errorMessage));
    }

    @IsTest
    static void testCaseInsensitiveEmailMatch() {
        Test.setMock(HttpCalloutMock.class, new LoyaltyMock(200, MOCK_BODY));

        GetLoyaltyTierAction.Request req = new GetLoyaltyTierAction.Request();
        req.contactEmail = 'SOFIA.RODRIGUEZ@EXAMPLE.COM';

        Test.startTest();
        List<GetLoyaltyTierAction.Response> results = GetLoyaltyTierAction.execute(
            new List<GetLoyaltyTierAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals('Platinum', results[0].loyaltyTier, 'Email match must be case-insensitive');
    }
}
