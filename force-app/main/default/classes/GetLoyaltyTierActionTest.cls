@IsTest
private class GetLoyaltyTierActionTest {

    private static final Map<String, Map<String, String>> MOCK_DATA =
        new Map<String, Map<String, String>>{
            'sofiarodriguez@example.com' => new Map<String, String>{
                'tier'     => 'Platinum',
                'memberId' => 'LYL-00123'
            },
            'marcusjohnson@example.com' => new Map<String, String>{
                'tier'     => 'Gold',
                'memberId' => 'LYL-00456'
            }
        };

    @IsTest
    static void testPlatinumTierReturned() {
        GetLoyaltyTierAction.dmoTestData = MOCK_DATA;

        GetLoyaltyTierAction.Request req = new GetLoyaltyTierAction.Request();
        req.contactEmail = 'sofiarodriguez@example.com';

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
        GetLoyaltyTierAction.dmoTestData = MOCK_DATA;

        GetLoyaltyTierAction.Request req = new GetLoyaltyTierAction.Request();
        req.contactEmail = 'marcusjohnson@example.com';

        Test.startTest();
        List<GetLoyaltyTierAction.Response> results = GetLoyaltyTierAction.execute(
            new List<GetLoyaltyTierAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals('Gold', results[0].loyaltyTier);
        System.assert(results[0].isSuccess);
    }

    @IsTest
    static void testCaseInsensitiveEmailMatch() {
        GetLoyaltyTierAction.dmoTestData = MOCK_DATA;

        GetLoyaltyTierAction.Request req = new GetLoyaltyTierAction.Request();
        req.contactEmail = 'SOFIARODRIGUEZ@EXAMPLE.COM';

        Test.startTest();
        List<GetLoyaltyTierAction.Response> results = GetLoyaltyTierAction.execute(
            new List<GetLoyaltyTierAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals('Platinum', results[0].loyaltyTier, 'Email match must be case-insensitive');
    }

    @IsTest
    static void testUnknownEmailReturnsStandard() {
        GetLoyaltyTierAction.dmoTestData = new Map<String, Map<String, String>>();

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
    static void testLiveSoqlPathReturnsStandard() {
        // dmoTestData = null forces the real Database.query path.
        // In test context the DMO returns empty or throws — both yield Standard gracefully.
        GetLoyaltyTierAction.dmoTestData   = null;
        GetLoyaltyTierAction.forceException = false;

        GetLoyaltyTierAction.Request req = new GetLoyaltyTierAction.Request();
        req.contactEmail = 'live-path-test@example.com';

        Test.startTest();
        List<GetLoyaltyTierAction.Response> results = GetLoyaltyTierAction.execute(
            new List<GetLoyaltyTierAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals('Standard', results[0].loyaltyTier);
        System.assert(!results[0].isSuccess);
    }

    @IsTest
    static void testExceptionReturnsStandard() {
        GetLoyaltyTierAction.dmoTestData  = null;
        GetLoyaltyTierAction.forceException = true;

        GetLoyaltyTierAction.Request req = new GetLoyaltyTierAction.Request();
        req.contactEmail = 'sofia@example.com';

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
}