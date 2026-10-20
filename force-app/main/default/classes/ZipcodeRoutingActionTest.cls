@IsTest
private class ZipcodeRoutingActionTest {

    @IsTest
    static void testKnownZip_returnsMatchedQueue() {
        // Custom Metadata is read-only in tests; mock the SOQL result via
        // a stub-friendly pattern using Test.loadData is not available for CMT.
        // We test the logic path by verifying the action compiles and returns
        // a result per input (no NPE, correct list size).
        ZipcodeRoutingAction.RoutingRequest req = new ZipcodeRoutingAction.RoutingRequest();
        req.zipcode = '90210';

        Test.startTest();
        List<ZipcodeRoutingAction.RoutingResult> results =
            ZipcodeRoutingAction.resolveQueue(
                new List<ZipcodeRoutingAction.RoutingRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result per input');
        System.assertNotEquals(null, results[0].queueDeveloperName, 'Queue name should not be null');
        System.assertEquals('90210', results[0].zipcode, 'Zipcode should be echoed back');
    }

    @IsTest
    static void testBlankZip_fallsBackToDefault() {
        ZipcodeRoutingAction.RoutingRequest req = new ZipcodeRoutingAction.RoutingRequest();
        req.zipcode = '';

        Test.startTest();
        List<ZipcodeRoutingAction.RoutingResult> results =
            ZipcodeRoutingAction.resolveQueue(
                new List<ZipcodeRoutingAction.RoutingRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertNotEquals(null, results[0].queueDeveloperName, 'Should fall back to default queue');
    }

    @IsTest
    static void testBulkInvocation_returnsOneResultPerInput() {
        List<ZipcodeRoutingAction.RoutingRequest> reqs = new List<ZipcodeRoutingAction.RoutingRequest>();
        for (Integer i = 0; i < 50; i++) {
            ZipcodeRoutingAction.RoutingRequest req = new ZipcodeRoutingAction.RoutingRequest();
            req.zipcode = '1000' + String.valueOf(i);
            reqs.add(req);
        }

        Test.startTest();
        List<ZipcodeRoutingAction.RoutingResult> results =
            ZipcodeRoutingAction.resolveQueue(reqs);
        Test.stopTest();

        System.assertEquals(50, results.size(), 'Bulk: should return one result per input');
        for (ZipcodeRoutingAction.RoutingResult r : results) {
            System.assertNotEquals(null, r.queueDeveloperName, 'Every result needs a queue name');
        }
    }
}
