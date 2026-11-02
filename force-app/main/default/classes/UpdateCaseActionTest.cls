@IsTest
private class UpdateCaseActionTest {

    @TestSetup
    static void setup() {
        insert new Case(Subject = 'Test Update Case', Status = 'New', Origin = 'Chat');
    }

    @IsTest
    static void testHappyPath() {
        Case c = [SELECT Id FROM Case WHERE Subject = 'Test Update Case' LIMIT 1];

        UpdateCaseAction.UpdateCaseRequest req = new UpdateCaseAction.UpdateCaseRequest();
        req.caseId  = c.Id;
        req.comment = 'Diner provided additional details.';

        Test.startTest();
        List<UpdateCaseAction.UpdateCaseResult> results =
            UpdateCaseAction.execute(new List<UpdateCaseAction.UpdateCaseRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'Expected success');
        System.assertNotEquals(null, results[0].confirmationMessage);
    }

    @IsTest
    static void testBlankCaseId() {
        UpdateCaseAction.UpdateCaseRequest req = new UpdateCaseAction.UpdateCaseRequest();
        req.caseId  = '';
        req.comment = 'Some comment';

        Test.startTest();
        List<UpdateCaseAction.UpdateCaseResult> results =
            UpdateCaseAction.execute(new List<UpdateCaseAction.UpdateCaseRequest>{ req });
        Test.stopTest();

        System.assert(!results[0].isSuccess);
        System.assertNotEquals(null, results[0].errorMessage);
    }

    @IsTest
    static void testBlankComment() {
        Case c = [SELECT Id FROM Case WHERE Subject = 'Test Update Case' LIMIT 1];

        UpdateCaseAction.UpdateCaseRequest req = new UpdateCaseAction.UpdateCaseRequest();
        req.caseId  = c.Id;
        req.comment = '';

        Test.startTest();
        List<UpdateCaseAction.UpdateCaseResult> results =
            UpdateCaseAction.execute(new List<UpdateCaseAction.UpdateCaseRequest>{ req });
        Test.stopTest();

        System.assert(!results[0].isSuccess);
    }
}
