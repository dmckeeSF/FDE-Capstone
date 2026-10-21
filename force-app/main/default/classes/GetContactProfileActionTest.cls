@IsTest
private class GetContactProfileActionTest {

    @TestSetup
    static void setup() {
        Contact c = new Contact(
            FirstName     = 'Bob',
            LastName      = 'Garcia',
            Email         = 'bob.garcia@example.com',
            Loyalty_Tier__c = 'Gold'
        );
        insert c;
    }

    @IsTest
    static void testHappyPath() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Garcia' LIMIT 1];

        GetContactProfileAction.ContactRequest req = new GetContactProfileAction.ContactRequest();
        req.contactId = c.Id;

        Test.startTest();
        List<GetContactProfileAction.ContactProfileDTO> results =
            GetContactProfileAction.execute(new List<GetContactProfileAction.ContactRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Bob',   results[0].firstName);
        System.assertEquals('Garcia', results[0].lastName);
        System.assertEquals('Gold',  results[0].loyaltyTier);
        System.assertEquals('bob.garcia@example.com', results[0].email);
    }

    @IsTest
    static void testMissingContactId() {
        GetContactProfileAction.ContactRequest req = new GetContactProfileAction.ContactRequest();
        req.contactId = '';

        Boolean threw = false;
        Test.startTest();
        try {
            GetContactProfileAction.execute(new List<GetContactProfileAction.ContactRequest>{ req });
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Expected exception for blank contactId');
    }

    @IsTest
    static void testContactNotFound() {
        GetContactProfileAction.ContactRequest req = new GetContactProfileAction.ContactRequest();
        req.contactId = '003000000000000AAA'; // valid format, non-existent

        Boolean threw = false;
        Test.startTest();
        try {
            GetContactProfileAction.execute(new List<GetContactProfileAction.ContactRequest>{ req });
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Expected exception for unknown contact');
    }
}
