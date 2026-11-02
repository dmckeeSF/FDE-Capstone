public without sharing class ReservationSharingHandler {

    public static void grantDinerAccess(List<Reservation__c> newRecords, Map<Id, Reservation__c> oldMap) {
        Set<Id> contactIds = new Set<Id>();

        for (Reservation__c r : newRecords) {
            if (r.Diner__c == null) continue;
            if (oldMap == null || r.Diner__c != oldMap.get(r.Id).Diner__c) {
                contactIds.add(r.Diner__c);
            }
        }

        if (contactIds.isEmpty()) return;

        Map<Id, Id> contactToUser = new Map<Id, Id>();
        for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :contactIds AND IsActive = true]) {
            contactToUser.put(u.ContactId, u.Id);
        }

        if (oldMap != null) {
            revokeStaleDinerAccess(newRecords, oldMap, contactToUser);
        }

        List<Reservation__Share> toInsert = new List<Reservation__Share>();
        for (Reservation__c r : newRecords) {
            if (r.Diner__c == null) continue;
            Id userId = contactToUser.get(r.Diner__c);
            if (userId == null) continue;
            if (oldMap != null && r.Diner__c == oldMap.get(r.Id).Diner__c) continue;
            toInsert.add(new Reservation__Share(
                ParentId = r.Id,
                UserOrGroupId = userId,
                AccessLevel = 'Read',
                RowCause = Schema.Reservation__Share.RowCause.Manual
            ));
        }

        if (!toInsert.isEmpty()) {
            Database.insert(toInsert, false);
        }
    }

    private static void revokeStaleDinerAccess(
        List<Reservation__c> newRecords,
        Map<Id, Reservation__c> oldMap,
        Map<Id, Id> contactToUser
    ) {
        Set<Id> changedIds = new Set<Id>();
        Set<Id> oldContactIds = new Set<Id>();

        for (Reservation__c r : newRecords) {
            if (r.Diner__c != oldMap.get(r.Id).Diner__c) {
                changedIds.add(r.Id);
                if (oldMap.get(r.Id).Diner__c != null) {
                    oldContactIds.add(oldMap.get(r.Id).Diner__c);
                }
            }
        }

        if (changedIds.isEmpty()) return;

        Map<Id, Id> oldContactToUser = new Map<Id, Id>();
        for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :oldContactIds AND IsActive = true]) {
            oldContactToUser.put(u.ContactId, u.Id);
        }

        List<Reservation__Share> toDelete = [
            SELECT Id FROM Reservation__Share
            WHERE ParentId IN :changedIds
            AND UserOrGroupId IN :oldContactToUser.values()
            AND RowCause = :Schema.Reservation__Share.RowCause.Manual
        ];

        if (!toDelete.isEmpty()) {
            Database.delete(toDelete, false);
        }
    }

    public static void revokeDinerAccess(List<Reservation__c> deletedRecords) {
        Set<Id> reservationIds = new Set<Id>();
        for (Reservation__c r : deletedRecords) {
            reservationIds.add(r.Id);
        }
        List<Reservation__Share> toDelete = [
            SELECT Id FROM Reservation__Share
            WHERE ParentId IN :reservationIds
            AND RowCause = :Schema.Reservation__Share.RowCause.Manual
        ];
        if (!toDelete.isEmpty()) {
            Database.delete(toDelete, false);
        }
    }
}
