@IsTest
private class ReservationNameSyncTest {

    @IsTest
    static void testNameSyncedToBookingReference() {
        Id restaurantRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1].Id;
        Account rest = new Account(Name = 'Test Sync Grill', RecordTypeId = restaurantRT);
        insert rest;
        Contact diner = new Contact(FirstName = 'Sync', LastName = 'Test', Email = 'sync@test.com', AccountId = rest.Id);
        insert diner;

        Reservation__c res = new Reservation__c(
            Diner__c = diner.Id,
            Restaurant__c = rest.Id,
            Reservation_Date__c = Date.today().addDays(5),
            Reservation_Time__c = Time.newInstance(18, 0, 0, 0),
            Party_Size__c = 2,
            Status__c = 'Confirmed'
        );

        Test.startTest();
        insert res;
        Test.stopTest();

        Reservation__c refreshed = [SELECT Name, Booking_Reference__c FROM Reservation__c WHERE Id = :res.Id];
        Assert.areEqual(refreshed.Booking_Reference__c, refreshed.Name, 'Name must match Booking_Reference__c after insert');
        Assert.isTrue(refreshed.Name.startsWith('RES-'), 'Name must follow RES-XXXXXX format');
    }
}
