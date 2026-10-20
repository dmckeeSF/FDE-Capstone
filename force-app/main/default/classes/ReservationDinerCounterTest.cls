@IsTest
private class ReservationDinerCounterTest {

    private static Contact createDiner(String firstName, String lastName) {
        Id restaurantRT    = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1].Id;
        Id customerGroupRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Customer_Group' LIMIT 1].Id;
        // Restaurant account used for Reservation.Restaurant__c lookups
        Account rest = new Account(Name = 'Test Restaurant ' + firstName, RecordTypeId = restaurantRT);
        insert rest;
        // Individual diner account — Customer_Group RT (one per diner)
        Account dinerAcct = new Account(Name = 'Diner Account ' + firstName, RecordTypeId = customerGroupRT);
        insert dinerAcct;
        Contact c = new Contact(FirstName = firstName, LastName = lastName, Email = firstName + '@test.com', AccountId = dinerAcct.Id);
        insert c;
        return c;
    }

    private static Reservation__c makeRes(Id contactId, Id restaurantId) {
        return new Reservation__c(
            Diner__c             = contactId,
            Restaurant__c        = restaurantId,
            Reservation_Date__c  = Date.today().addDays(7),
            Reservation_Time__c  = Time.newInstance(19, 0, 0, 0),
            Party_Size__c        = 2,
            Status__c            = 'Confirmed'
        );
    }

    @IsTest
    static void testInsertIncrementsCount() {
        Contact diner = createDiner('Test', 'Diner');
        Account rest = [SELECT Id FROM Account WHERE Name = 'Test Restaurant Test' LIMIT 1];

        Test.startTest();
        insert makeRes(diner.Id, rest.Id);
        Test.stopTest();

        Assert.areEqual(1, [SELECT Lifetime_Reservations__c FROM Contact WHERE Id = :diner.Id].Lifetime_Reservations__c);
    }

    @IsTest
    static void testDeleteDecrementsCount() {
        Contact diner = createDiner('Del', 'Diner');
        Account rest = [SELECT Id FROM Account WHERE Name = 'Test Restaurant Del' LIMIT 1];
        Reservation__c r1 = makeRes(diner.Id, rest.Id);
        Reservation__c r2 = makeRes(diner.Id, rest.Id);
        insert new List<Reservation__c>{ r1, r2 };

        Test.startTest();
        delete r1;
        Test.stopTest();

        Assert.areEqual(1, [SELECT Lifetime_Reservations__c FROM Contact WHERE Id = :diner.Id].Lifetime_Reservations__c);
    }

    @IsTest
    static void testUndeleteRestoresCount() {
        Contact diner = createDiner('Und', 'Diner');
        Account rest = [SELECT Id FROM Account WHERE Name = 'Test Restaurant Und' LIMIT 1];
        Reservation__c r = makeRes(diner.Id, rest.Id);
        insert r;
        delete r;

        Test.startTest();
        undelete r;
        Test.stopTest();

        Assert.areEqual(1, [SELECT Lifetime_Reservations__c FROM Contact WHERE Id = :diner.Id].Lifetime_Reservations__c);
    }

    @IsTest
    static void testMultipleDinersIsolated() {
        Contact d1 = createDiner('Alice', 'Diner');
        Contact d2 = createDiner('Bob', 'Diner2');
        Account r1 = [SELECT Id FROM Account WHERE Name = 'Test Restaurant Alice' LIMIT 1];
        Account r2 = [SELECT Id FROM Account WHERE Name = 'Test Restaurant Bob' LIMIT 1];

        Test.startTest();
        insert new List<Reservation__c>{
            makeRes(d1.Id, r1.Id),
            makeRes(d1.Id, r1.Id),
            makeRes(d2.Id, r2.Id)
        };
        Test.stopTest();

        Map<Id, Contact> contacts = new Map<Id, Contact>(
            [SELECT Id, Lifetime_Reservations__c FROM Contact WHERE Id IN :new Set<Id>{ d1.Id, d2.Id }]
        );
        Assert.areEqual(2, contacts.get(d1.Id).Lifetime_Reservations__c);
        Assert.areEqual(1, contacts.get(d2.Id).Lifetime_Reservations__c);
    }

    @IsTest
    static void testNullDinerSkipped() {
        Id restaurantRT    = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1].Id;
        Id customerGroupRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Customer_Group' LIMIT 1].Id;
        Account rest = new Account(Name = 'Test Null Diner Rest', RecordTypeId = restaurantRT);
        insert rest;
        Account dinerAcct = new Account(Name = 'Null Diner Account', RecordTypeId = customerGroupRT);
        insert dinerAcct;
        Contact c = new Contact(FirstName = 'Null', LastName = 'Test', Email = 'null@test.com', AccountId = dinerAcct.Id);
        insert c;
        Test.startTest();
        insert makeRes(c.Id, rest.Id);
        Test.stopTest();
        Assert.areEqual(1, [SELECT Lifetime_Reservations__c FROM Contact WHERE Id = :c.Id].Lifetime_Reservations__c);
    }
}
