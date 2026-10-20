trigger ReservationNameSync on Reservation__c (after insert) {
    List<Reservation__c> toUpdate = new List<Reservation__c>();
    for (Reservation__c rec : Trigger.new) {
        if (rec.Booking_Reference__c != null && rec.Booking_Reference__c != rec.Name) {
            toUpdate.add(new Reservation__c(Id = rec.Id, Name = rec.Booking_Reference__c));
        }
    }
    if (!toUpdate.isEmpty()) {
        update toUpdate;
    }
}