@IsTest
private class ReservationSharingTest {

    @TestSetup
    static void setup() {
        Id restaurantRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant' LIMIT 1].Id;
        Id communityProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus Login User' LIMIT 1].Id;

        Account rest = new Account(Name = 'Test Grill', RecordTypeId = restaurantRT);
        insert rest;

        Contact alice = new Contact(FirstName = 'Alice', LastName = 'Share', Email = 'alice.share@test.com', AccountId = rest.Id);
        Contact bob   = new Contact(FirstName = 'Bob',   LastName = 'Share', Email = 'bob.share@test.com',   AccountId = rest.Id);
        insert new List<Contact>{ alice, bob };

        User aliceUser = new User(
            ProfileId = communityProfileId, ContactId = alice.Id,
            FirstName = 'Alice', LastName = 'Share', Email = 'alice.share@test.com',
            Username = 'alice.share.test@ariaportal.test', Alias = 'ashare',
            CommunityNickname = 'aliceshare1', TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        User bobUser = new User(
            ProfileId = communityProfileId, ContactId = bob.Id,
            FirstName = 'Bob', LastName = 'Share', Email = 'bob.share@test.com',
            Username = 'bob.share.test@ariaportal.test', Alias = 'bshare',
            CommunityNickname = 'bobshare1', TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        insert new List<User>{ aliceUser, bobUser };

        Reservation__c aliceRes = new Reservation__c(
            Diner__c = alice.Id, Restaurant__c = rest.Id,
            Reservation_Date__c = Date.today().addDays(7),
            Reservation_Time__c = Time.newInstance(19, 0, 0, 0),
            Party_Size__c = 2, Status__c = 'Confirmed'
        );
        Reservation__c bobRes = new Reservation__c(
            Diner__c = bob.Id, Restaurant__c = rest.Id,
            Reservation_Date__c = Date.today().addDays(14),
            Reservation_Time__c = Time.newInstance(19, 0, 0, 0),
            Party_Size__c = 2, Status__c = 'Confirmed'
        );
        insert new List<Reservation__c>{ aliceRes, bobRes };

        Id psId = [SELECT Id FROM PermissionSet WHERE Name = 'Diner_Community_Access' LIMIT 1].Id;
        insert new List<PermissionSetAssignment>{
            new PermissionSetAssignment(PermissionSetId = psId, AssigneeId = aliceUser.Id),
            new PermissionSetAssignment(PermissionSetId = psId, AssigneeId = bobUser.Id)
        };
    }

    @IsTest
    static void testDinerSeesOnlyOwnReservations() {
        User bobUser = [SELECT Id FROM User WHERE Username = 'bob.share.test@ariaportal.test' LIMIT 1];

        System.runAs(bobUser) {
            List<Reservation__c> visible = [SELECT Id, Diner__c FROM Reservation__c];
            Assert.areEqual(1, visible.size(), 'Bob should see only his own reservation');
            Contact bob = [SELECT Id FROM Contact WHERE LastName = 'Share' AND FirstName = 'Bob' LIMIT 1];
            Assert.areEqual(bob.Id, visible[0].Diner__c, 'Visible reservation must belong to Bob');
        }
    }

    @IsTest
    static void testDinerCannotSeeOtherDinersReservations() {
        User bobUser = [SELECT Id FROM User WHERE Username = 'bob.share.test@ariaportal.test' LIMIT 1];
        Contact alice = [SELECT Id FROM Contact WHERE LastName = 'Share' AND FirstName = 'Alice' LIMIT 1];

        System.runAs(bobUser) {
            List<Reservation__c> aliceRes = [SELECT Id FROM Reservation__c WHERE Diner__c = :alice.Id];
            Assert.areEqual(0, aliceRes.size(), 'Bob must not see Alice\'s reservation');
        }
    }

    @IsTest
    static void testDinerCanCreateOwnReservation() {
        User bobUser = [SELECT Id FROM User WHERE Username = 'bob.share.test@ariaportal.test' LIMIT 1];
        Contact bob = [SELECT Id FROM Contact WHERE LastName = 'Share' AND FirstName = 'Bob' LIMIT 1];
        Account rest = [SELECT Id FROM Account WHERE Name = 'Test Grill' LIMIT 1];

        System.runAs(bobUser) {
            Reservation__c newRes = new Reservation__c(
                Diner__c = bob.Id, Restaurant__c = rest.Id,
                Reservation_Date__c = Date.today().addDays(21),
                Reservation_Time__c = Time.newInstance(18, 0, 0, 0),
                Party_Size__c = 3, Status__c = 'Confirmed'
            );
            insert newRes;
            Assert.isNotNull(newRes.Id, 'Bob should be able to create a reservation');
        }
    }
}
