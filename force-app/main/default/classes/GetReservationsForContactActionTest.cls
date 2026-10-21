@IsTest
private class GetReservationsForContactActionTest {

    @TestSetup
    static void setup() {
        Contact c = new Contact(FirstName = 'Bob', LastName = 'Garcia', Email = 'bob@example.com');
        insert c;

        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1];
        Account restaurant = new Account(Name = 'Test Bistro', RecordTypeId = rt.Id);
        insert restaurant;

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
                Status__c            = 'Pending'
            )
        };
    }

    @IsTest
    static void testHappyPath() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Garcia' LIMIT 1];

        GetReservationsForContactAction.ReservationListRequest req = new GetReservationsForContactAction.ReservationListRequest();
        req.contactId = c.Id;

        Test.startTest();
        List<GetReservationsForContactAction.ReservationListDTO> results =
            GetReservationsForContactAction.execute(
                new List<GetReservationsForContactAction.ReservationListRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(2, results[0].totalCount);
        System.assert(results[0].reservationSummaries.contains('Test Bistro'), 'Expected restaurant name in summaries');
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
    static void testMissingContactId() {
        GetReservationsForContactAction.ReservationListRequest req = new GetReservationsForContactAction.ReservationListRequest();
        req.contactId = '';

        Boolean threw = false;
        Test.startTest();
        try {
            GetReservationsForContactAction.execute(
                new List<GetReservationsForContactAction.ReservationListRequest>{ req }
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Expected exception for blank contactId');
    }
}
