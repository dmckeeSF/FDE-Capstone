@IsTest
private class SendPasswordResetActionTest {

    @TestSetup
    static void setup() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];
        Account acct = new Account(Name = 'Test Account', RecordTypeId = rt.Id);
        insert acct;
        insert new Contact(FirstName = 'Reset', LastName = 'Tester', Email = 'resettester@example.com', AccountId = acct.Id);
    }

    @IsTest
    static void testBlankContactIdReturnsError() {
        SendPasswordResetAction.PasswordResetRequest req = new SendPasswordResetAction.PasswordResetRequest();
        req.contactId = '';

        Test.startTest();
        List<SendPasswordResetAction.PasswordResetResult> results =
            SendPasswordResetAction.execute(new List<SendPasswordResetAction.PasswordResetRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].errorMessage.contains('Contact ID'), 'Expected contact ID error message');
    }

    @IsTest
    static void testNoActivePortalUserReturnsError() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Tester' LIMIT 1];

        SendPasswordResetAction.PasswordResetRequest req = new SendPasswordResetAction.PasswordResetRequest();
        req.contactId = c.Id;

        Test.startTest();
        List<SendPasswordResetAction.PasswordResetResult> results =
            SendPasswordResetAction.execute(new List<SendPasswordResetAction.PasswordResetRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].errorMessage.contains('No active portal user'), 'Expected no portal user message');
    }

    @IsTest
    static void testNullContactIdReturnsError() {
        SendPasswordResetAction.PasswordResetRequest req = new SendPasswordResetAction.PasswordResetRequest();
        req.contactId = null;

        Test.startTest();
        List<SendPasswordResetAction.PasswordResetResult> results =
            SendPasswordResetAction.execute(new List<SendPasswordResetAction.PasswordResetRequest>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess);
    }
}
