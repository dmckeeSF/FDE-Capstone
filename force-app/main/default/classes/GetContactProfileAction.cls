public with sharing class GetContactProfileAction {

    @InvocableMethod(label='Get Contact Profile' description='Retrieves authenticated diner profile fields by Contact Id')
    public static List<ContactProfileDTO> execute(List<ContactRequest> requests) {
        List<ContactProfileDTO> results = new List<ContactProfileDTO>();
        for (ContactRequest req : requests) {
            if (String.isBlank(req.contactId)) {
                throw new AuraHandledException('Contact ID is required.');
            }
            List<Contact> contacts = [
                SELECT FirstName, LastName, Loyalty_Tier__c, Email
                FROM Contact
                WHERE Id = :req.contactId
                LIMIT 1
            ];
            if (contacts.isEmpty()) {
                throw new AuraHandledException('Contact not found.');
            }
            Contact c = contacts[0];
            ContactProfileDTO dto = new ContactProfileDTO();
            dto.firstName    = c.FirstName;
            dto.lastName     = c.LastName;
            dto.loyaltyTier  = c.Loyalty_Tier__c;
            dto.email        = c.Email;
            results.add(dto);
        }
        return results;
    }

    public class ContactRequest {
        @InvocableVariable(required=true label='Contact Id') public String contactId;
    }

    public class ContactProfileDTO {
        @InvocableVariable public String firstName;
        @InvocableVariable public String lastName;
        @InvocableVariable public String loyaltyTier;
        @InvocableVariable public String email;
    }
}
