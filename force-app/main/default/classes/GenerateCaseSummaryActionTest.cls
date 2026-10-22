@isTest
private class GenerateCaseSummaryActionTest {

    @TestSetup
    static void setup() {
        Case c = new Case(
            Subject = 'Aria Escalation: test',
            Status = 'New',
            Priority = 'High',
            Origin = 'Chat'
        );
        insert c;
    }

    @isTest
    static void testGenerateReturnsResponse() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        GenerateCaseSummaryAction.Request req = new GenerateCaseSummaryAction.Request();
        req.caseId = c.Id;

        Test.startTest();
        // ConnectApi.EinsteinLLM is not callable in unit tests; verify the action
        // handles the callout exception gracefully and returns a structured response.
        List<GenerateCaseSummaryAction.Response> results =
            GenerateCaseSummaryAction.generate(new List<GenerateCaseSummaryAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one response');
        System.assertNotEquals(null, results[0], 'Response must not be null');
        // isSuccess will be false in test context (no real callout); error message set
        System.assertNotEquals(null, results[0].isSuccess, 'isSuccess must be set');
    }

    @isTest
    static void testNullCaseIdHandled() {
        GenerateCaseSummaryAction.Request req = new GenerateCaseSummaryAction.Request();
        req.caseId = null;

        Test.startTest();
        List<GenerateCaseSummaryAction.Response> results =
            GenerateCaseSummaryAction.generate(new List<GenerateCaseSummaryAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess, 'Null caseId should return isSuccess=false');
        System.assertNotEquals(null, results[0].errorMessage, 'Error message must be populated');
    }
}
