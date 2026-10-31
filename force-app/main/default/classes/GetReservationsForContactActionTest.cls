@IsTest
private class GetReservationsForContactActionTest {

    @TestSetup
    static void setup() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];

        Account restaurant = new Account(Name = 'Test Bistro', RecordTypeId = rt.Id);
        insert restaurant;

        // Use the same Restaurant record type for the diner's account so insert works
        // in PersonAccount-enabled orgs without needing a PersonAccount RecordType.
        Account dinerAcct = new Account(Name = 'Garcia Household', RecordTypeId = rt.Id);
        insert dinerAcct;

        Contact c = new Contact(
            FirstName = 'Bob',
            LastName  = 'Garcia',
            Email     = 'bob@example.com',
            AccountId = dinerAcct.Id
        );
        insert c;

        insert new List<Reservation__c>{
            new Reservation__c(
                Diner__c             = c.Id,
                Restaurant__c        = restaurant.Id,
                Reservation_Date__c  = Date.today().addDays(5),
                Reservation_Time__c  = Time.newInstance(19, 0, 0, 0),
                Party_Size__c        = 2,
                Status__c            = 'Confirmed'
            ),
            new Reservation__c(
                Diner__c             = c.Id,
                Restaurant__c        = restaurant.Id,
                Reservation_Date__c  = Date.today().addDays(10),
                Reservation_Time__c  = Time.newInstance(20, 0, 0, 0),
                Party_Size__c        = 4,
                Status__c            = 'Modified'
            )
        };
    }

    @IsTest
    static void testHappyPathContactId() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Garcia' LIMIT 1];

        GetReservationsForContactAction.ReservationListRequest req = new GetReservationsForContactAction.ReservationListRequest();
        req.contactId = c.Id;

        Test.startTest();
        List<GetReservationsForContactAction.ReservationListDTO> results =
            GetReservationsForContactAction.execute(
                new List<GetReservationsForContactAction.ReservationListRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(2, results[0].totalCount);
        System.assert(results[0].reservationSummaries.contains('Test Bistro'), 'Expected restaurant name in summaries');
    }

    @IsTest
    static void testPersonAccountIdLookup() {
        // Experience Cloud person account sites pass Account ID (001...) instead of Contact ID.
        Contact c = [SELECT Id, AccountId FROM Contact WHERE LastName = 'Garcia' LIMIT 1];

        GetReservationsForContactAction.ReservationListRequest req = new GetReservationsForContactAction.ReservationListRequest();
        req.contactId = c.AccountId;

        Test.startTest();
        List<GetReservationsForContactAction.ReservationListDTO> results =
            GetReservationsForContactAction.execute(
                new List<GetReservationsForContactAction.ReservationListRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(2, results[0].totalCount, 'Should find reservations when AccountId passed instead of ContactId');
    }

    @IsTest
    static void testNoReservations() {
        Contact other = new Contact(FirstName = 'No', LastName = 'Reservations', Email = 'none@example.com');
        insert other;

        GetReservationsForContactAction.ReservationListRequest req = new GetReservationsForContactAction.ReservationListRequest();
        req.contactId = other.Id;

        Test.startTest();
        List<GetReservationsForContactAction.ReservationListDTO> results =
            GetReservationsForContactAction.execute(
                new List<GetReservationsForContactAction.ReservationListRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(0, results[0].totalCount);
    }

    @IsTest
    static void testBlankContactIdReturnsEmpty() {
        GetReservationsForContactAction.ReservationListRequest req = new GetReservationsForContactAction.ReservationListRequest();
        req.contactId = '';

        Test.startTest();
        List<GetReservationsForContactAction.ReservationListDTO> results =
            GetReservationsForContactAction.execute(
                new List<GetReservationsForContactAction.ReservationListRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(0, results[0].totalCount, 'Blank contactId should return 0 results');
    }
}
