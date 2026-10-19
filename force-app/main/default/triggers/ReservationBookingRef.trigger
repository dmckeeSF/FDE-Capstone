trigger ReservationBookingRef on Reservation__c (before insert) {
    for (Reservation__c res : Trigger.new) {
        if (String.isBlank(res.Booking_Ref__c)) {
            res.Booking_Ref__c = ReservationBookingRefHelper.generate();
        }
    }
}
