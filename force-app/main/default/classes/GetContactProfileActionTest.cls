@IsTest
private class GetContactProfileActionTest {

    @TestSetup
    static void setup() {
        // Use a non-PersonAccount record type so Account insert works in PersonAccount-enabled orgs.
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];
        Account acct = new Account(Name = 'Garcia Test Account', RecordTypeId = rt.Id);
        insert acct;

        Contact c = new Contact(
            FirstName       = 'Bob',
            LastName        = 'Garcia',
            Email           = 'bob.garcia@example.com',
            Loyalty_Tier__c = 'Gold',
            AccountId       = acct.Id
        );
        insert c;
    }

    @IsTest
    static void testHappyPathContactId() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Garcia' LIMIT 1];

        GetContactProfileAction.ContactRequest req = new GetContactProfileAction.ContactRequest();
        req.contactId = c.Id;

        Test.startTest();
        List<GetContactProfileAction.ContactProfileDTO> results =
            GetContactProfileAction.execute(new List<GetContactProfileAction.ContactRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Bob',    results[0].firstName);
        System.assertEquals('Garcia', results[0].lastName);
        System.assertEquals('Gold',   results[0].loyaltyTier);
        System.assertEquals('bob.garcia@example.com', results[0].email);
        System.assert(results[0].profileFound, 'profileFound should be true');
    }

    @IsTest
    static void testPersonAccountIdLookup() {
        // Experience Cloud person account sites pass Account ID (001...) instead of Contact ID.
        Contact c = [SELECT Id, AccountId FROM Contact WHERE LastName = 'Garcia' LIMIT 1];

        GetContactProfileAction.ContactRequest req = new GetContactProfileAction.ContactRequest();
        req.contactId = c.AccountId;

        Test.startTest();
        List<GetContactProfileAction.ContactProfileDTO> results =
            GetContactProfileAction.execute(new List<GetContactProfileAction.ContactRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Bob', results[0].firstName, 'Should resolve Contact via AccountId');
        System.assert(results[0].profileFound, 'profileFound should be true when resolved via Account');
    }

    @IsTest
    static void testBlankContactIdReturnsEmpty() {
        GetContactProfileAction.ContactRequest req = new GetContactProfileAction.ContactRequest();
        req.contactId = '';

        Test.startTest();
        List<GetContactProfileAction.ContactProfileDTO> results =
            GetContactProfileAction.execute(new List<GetContactProfileAction.ContactRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('', results[0].firstName);
        System.assert(!results[0].profileFound, 'profileFound should be false for blank contactId');
    }

    @IsTest
    static void testContactNotFoundReturnsEmpty() {
        GetContactProfileAction.ContactRequest req = new GetContactProfileAction.ContactRequest();
        req.contactId = '003000000000000AAA';

        Test.startTest();
        List<GetContactProfileAction.ContactProfileDTO> results =
            GetContactProfileAction.execute(new List<GetContactProfileAction.ContactRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('', results[0].firstName);
        System.assert(!results[0].profileFound, 'profileFound should be false when Contact not found');
    }
}
