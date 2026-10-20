trigger ReservationDinerCounter on Reservation__c (after insert, after delete, after undelete) {
    Set<Id> contactIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUndelete) {
        for (Reservation__c r : Trigger.new) {
            if (r.Diner__c != null) contactIds.add(r.Diner__c);
        }
    }
    if (Trigger.isDelete) {
        for (Reservation__c r : Trigger.old) {
            if (r.Diner__c != null) contactIds.add(r.Diner__c);
        }
    }

    if (contactIds.isEmpty()) return;

    Map<Id, Integer> countByContact = new Map<Id, Integer>();
    for (Id cId : contactIds) countByContact.put(cId, 0);

    for (AggregateResult ar : [
        SELECT Diner__c, COUNT(Id) cnt
        FROM Reservation__c
        WHERE Diner__c IN :contactIds
        GROUP BY Diner__c
    ]) {
        countByContact.put((Id) ar.get('Diner__c'), (Integer) ar.get('cnt'));
    }

    List<Contact> toUpdate = new List<Contact>();
    for (Id cId : countByContact.keySet()) {
        toUpdate.add(new Contact(Id = cId, Lifetime_Reservations__c = countByContact.get(cId)));
    }
    update toUpdate;
}
