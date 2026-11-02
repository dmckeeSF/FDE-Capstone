trigger ReservationDinerSharing on Reservation__c (after insert, after update, after delete) {
    if (Trigger.isInsert) {
        ReservationSharingHandler.grantDinerAccess(Trigger.new, null);
    } else if (Trigger.isUpdate) {
        ReservationSharingHandler.grantDinerAccess(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isDelete) {
        ReservationSharingHandler.revokeDinerAccess(Trigger.old);
    }
}
