@IsTest
private class GetDinerCasesActionTest {

    @TestSetup
    static void setup() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];
        Account acct = new Account(Name = 'Test Account', RecordTypeId = rt.Id);
        insert acct;
        Contact c = new Contact(FirstName = 'Test', LastName = 'Diner', Email = 'testdiner@example.com', AccountId = acct.Id);
        insert c;

        insert new List<Case>{
            new Case(ContactId = c.Id, Subject = 'Test Case 1', Status = 'New', Origin = 'Chat'),
            new Case(ContactId = c.Id, Subject = 'Test Case 2', Status = 'In Progress', Origin = 'Chat')
        };
    }

    @IsTest
    static void testReturnsCasesForContact() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Diner' LIMIT 1];

        GetDinerCasesAction.CaseListRequest req = new GetDinerCasesAction.CaseListRequest();
        req.contactId = c.Id;

        Test.startTest();
        List<GetDinerCasesAction.CaseListResult> results =
            GetDinerCasesAction.execute(new List<GetDinerCasesAction.CaseListRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(2, results[0].caseCount, 'Expected 2 cases');
        System.assert(results[0].caseSummaries.contains('Test Case 1'), 'Expected first case in summary');
    }

    @IsTest
    static void testBlankContactIdReturnsEmpty() {
        GetDinerCasesAction.CaseListRequest req = new GetDinerCasesAction.CaseListRequest();
        req.contactId = '';

        Test.startTest();
        List<GetDinerCasesAction.CaseListResult> results =
            GetDinerCasesAction.execute(new List<GetDinerCasesAction.CaseListRequest>{ req });
        Test.stopTest();

        System.assertEquals(0, results[0].caseCount);
        System.assertEquals('', results[0].caseSummaries);
    }

    @IsTest
    static void testNoCasesForContact() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];
        Account acct2 = new Account(Name = 'Other Account', RecordTypeId = rt.Id);
        insert acct2;
        Contact c2 = new Contact(FirstName = 'No', LastName = 'Cases', Email = 'nocases@example.com', AccountId = acct2.Id);
        insert c2;

        GetDinerCasesAction.CaseListRequest req = new GetDinerCasesAction.CaseListRequest();
        req.contactId = c2.Id;

        Test.startTest();
        List<GetDinerCasesAction.CaseListResult> results =
            GetDinerCasesAction.execute(new List<GetDinerCasesAction.CaseListRequest>{ req });
        Test.stopTest();

        System.assertEquals(0, results[0].caseCount);
    }
}
