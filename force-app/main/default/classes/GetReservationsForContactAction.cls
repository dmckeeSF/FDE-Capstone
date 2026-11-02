public without sharing class GetReservationsForContactAction {

    @InvocableMethod(label='Get Reservations For Contact' description='Lists upcoming confirmed and pending reservations for the authenticated diner')
    public static List<ReservationListDTO> execute(List<ReservationListRequest> requests) {
        List<ReservationListDTO> results = new List<ReservationListDTO>();
        for (ReservationListRequest req : requests) {
            if (String.isBlank(req.contactId)) {
                ReservationListDTO empty = new ReservationListDTO();
                empty.totalCount = 0;
                empty.reservationSummaries = '';
                results.add(empty);
                continue;
            }
            // Experience Cloud person account sites pass Account ID (001...) via
            // @MessagingEndUser.ContactId; resolve to Contact ID first in that case.
            String resolvedContactId = req.contactId;
            if (req.contactId.left(3) == '001') {
                List<Contact> personContacts = [
                    SELECT Id FROM Contact WHERE AccountId = :req.contactId LIMIT 1
                ];
                if (!personContacts.isEmpty()) {
                    resolvedContactId = personContacts[0].Id;
                }
            }
            List<Reservation__c> reservations = [
                SELECT Booking_Reference__c, Restaurant__r.Name,
                       Restaurant__r.Cancellation_Policy__c,
                       Reservation_Date__c, Reservation_Time__c,
                       Party_Size__c, Status__c
                FROM Reservation__c
                WHERE Diner__c   = :resolvedContactId
                  AND Status__c IN ('Confirmed', 'Modified')
                ORDER BY Reservation_Date__c ASC
                LIMIT 50
            ];
            ReservationListDTO dto = new ReservationListDTO();
            dto.totalCount = reservations.size();
            List<String> summaries = new List<String>();
            for (Reservation__c r : reservations) {
                summaries.add(
                    r.Booking_Reference__c + '|' +
                    r.Restaurant__r.Name   + '|' +
                    r.Reservation_Date__c  + '|' +
                    r.Reservation_Time__c  + '|' +
                    String.valueOf(r.Party_Size__c) + '|' +
                    r.Status__c + '|' +
                    (String.isNotBlank(r.Restaurant__r.Cancellation_Policy__c)
                        ? r.Restaurant__r.Cancellation_Policy__c
                        : '')
                );
            }
            dto.reservationSummaries = String.join(summaries, '\n');
            results.add(dto);
        }
        return results;
    }

    public class ReservationListRequest {
        @InvocableVariable(required=false label='Contact Id') public String contactId;
    }

    public class ReservationListDTO {
        @InvocableVariable public Integer totalCount;
        @InvocableVariable public String  reservationSummaries;
    }
}