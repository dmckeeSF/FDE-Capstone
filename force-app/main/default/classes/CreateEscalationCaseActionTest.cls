@IsTest
private class CreateEscalationCaseActionTest {

    @TestSetup
    static void setup() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];
        Account acct = new Account(Name = 'Test Account', RecordTypeId = rt.Id);
        insert acct;
        insert new Contact(FirstName = 'Test', LastName = 'Diner', Email = 'testdiner@example.com', AccountId = acct.Id);
    }

    @IsTest
    static void testWithContact() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Diner' LIMIT 1];

        CreateEscalationCaseAction.EscalationRequest req = new CreateEscalationCaseAction.EscalationRequest();
        req.contactId    = c.Id;
        req.issueSummary = 'Diner needs help with reservation';

        Test.startTest();
        List<CreateEscalationCaseAction.EscalationResult> results =
            CreateEscalationCaseAction.execute(new List<CreateEscalationCaseAction.EscalationRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'Expected success');
        System.assertNotEquals(null, results[0].caseId, 'Case ID should be set');
        System.assertNotEquals(null, results[0].caseNumber, 'Case number should be set');
    }

    @IsTest
    static void testWithoutContact() {
        CreateEscalationCaseAction.EscalationRequest req = new CreateEscalationCaseAction.EscalationRequest();
        req.issueSummary = 'Unauthenticated diner escalation';

        Test.startTest();
        List<CreateEscalationCaseAction.EscalationResult> results =
            CreateEscalationCaseAction.execute(new List<CreateEscalationCaseAction.EscalationRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'Expected success without contactId');
        System.assertNotEquals(null, results[0].caseId);
    }

    @IsTest
    static void testBlankSummaryDefaultsSubject() {
        CreateEscalationCaseAction.EscalationRequest req = new CreateEscalationCaseAction.EscalationRequest();
        req.issueSummary = '';

        Test.startTest();
        List<CreateEscalationCaseAction.EscalationResult> results =
            CreateEscalationCaseAction.execute(new List<CreateEscalationCaseAction.EscalationRequest>{ req });
        Test.stopTest();

        System.assert(results[0].isSuccess, 'Blank summary should still succeed');
        Case c = [SELECT Subject FROM Case WHERE Id = :results[0].caseId];
        System.assert(c.Subject.contains('No summary'), 'Subject should use default text');
    }
}
