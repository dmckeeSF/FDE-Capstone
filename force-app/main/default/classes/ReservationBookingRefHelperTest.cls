@IsTest
private class ReservationBookingRefHelperTest {
    @IsTest
    static void generatesEightCharRef() {
        String ref = ReservationBookingRefHelper.generate();
        Assert.areEqual(8, ref.length(), 'Reference must be 8 characters');
        Assert.areEqual(ref, ref.toUpperCase(), 'Reference must be uppercase');
    }

    @IsTest
    static void triggerPopulatesRefOnInsert() {
        Id rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1].Id;
        Account rest = new Account(Name = 'Test Restaurant', RecordTypeId = rtId);
        insert rest;
        Contact diner = new Contact(LastName = 'TestDiner', AccountId = rest.Id);
        insert diner;

        Reservation__c res = new Reservation__c(
            Restaurant__c = rest.Id,
            Diner__c = diner.Id,
            Reservation_Date__c = Date.today().addDays(30),
            Reservation_Time__c = Time.newInstance(19, 0, 0, 0),
            Party_Size__c = 2,
            Status__c = 'Confirmed'
        );
        insert res;

        res = [SELECT Booking_Ref__c FROM Reservation__c WHERE Id = :res.Id];
        Assert.areEqual(8, res.Booking_Ref__c.length(), 'Trigger must populate Booking_Ref__c');
    }
}
