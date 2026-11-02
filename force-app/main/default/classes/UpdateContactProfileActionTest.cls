@IsTest
private class UpdateContactProfileActionTest {

    @TestSetup
    static void setup() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];
        Account acct = new Account(Name = 'Test Account', RecordTypeId = rt.Id);
        insert acct;
        insert new Contact(FirstName = 'Test', LastName = 'Profile', Email = 'testprofile@example.com', AccountId = acct.Id, Phone = '555-1234');
    }

    @IsTest
    static void testUpdatePhone() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Profile' LIMIT 1];

        UpdateContactProfileAction.UpdateContactRequest req = new UpdateContactProfileAction.UpdateContactRequest();
        req.contactId = c.Id;
        req.fieldName = 'Phone';
        req.newValue  = '555-9999';

        Test.startTest();
        List<UpdateContactProfileAction.UpdateContactResult> results =
            UpdateContactProfileAction.execute(new List<UpdateContactProfileAction.UpdateContactRequest>{ req });
        Test.stopTest();

        System.assert(results[0].isSuccess, 'Expected success');
        System.assertNotEquals(null, results[0].confirmationMessage);

        Contact updated = [SELECT Phone FROM Contact WHERE Id = :c.Id];
        System.assertEquals('555-9999', updated.Phone, 'Phone should be updated');
    }

    @IsTest
    static void testBlankContactId() {
        UpdateContactProfileAction.UpdateContactRequest req = new UpdateContactProfileAction.UpdateContactRequest();
        req.contactId = '';
        req.fieldName = 'Phone';
        req.newValue  = '555-0000';

        Test.startTest();
        List<UpdateContactProfileAction.UpdateContactResult> results =
            UpdateContactProfileAction.execute(new List<UpdateContactProfileAction.UpdateContactRequest>{ req });
        Test.stopTest();

        System.assert(!results[0].isSuccess);
        System.assertNotEquals(null, results[0].errorMessage);
    }

    @IsTest
    static void testBlankFieldName() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Profile' LIMIT 1];

        UpdateContactProfileAction.UpdateContactRequest req = new UpdateContactProfileAction.UpdateContactRequest();
        req.contactId = c.Id;
        req.fieldName = '';
        req.newValue  = 'something';

        Test.startTest();
        List<UpdateContactProfileAction.UpdateContactResult> results =
            UpdateContactProfileAction.execute(new List<UpdateContactProfileAction.UpdateContactRequest>{ req });
        Test.stopTest();

        System.assert(!results[0].isSuccess);
    }
}
