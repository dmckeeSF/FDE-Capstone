public without sharing class GetContactProfileAction {

    @InvocableMethod(label='Get Contact Profile' description='Retrieves authenticated diner profile fields by Contact Id or MessagingEndUser Id')
    public static List<ContactProfileDTO> execute(List<ContactRequest> requests) {
        List<ContactProfileDTO> results = new List<ContactProfileDTO>();
        for (ContactRequest req : requests) {
            ContactProfileDTO dto = new ContactProfileDTO();
            dto.firstName    = '';
            dto.lastName     = '';
            dto.loyaltyTier  = '';
            dto.email        = '';
            dto.profileFound = false;

            // Resolve contactId — prefer explicit contactId, fall back to endUserId lookup.
            // endUserId = MessagingEndUser.Id (from @MessagingSession.MessagingEndUserId, always readable).
            String resolvedContactId = req.contactId;
            if (String.isBlank(resolvedContactId) && String.isNotBlank(req.endUserId)) {
                List<MessagingEndUser> meus = [
                    SELECT ContactId FROM MessagingEndUser WHERE Id = :req.endUserId LIMIT 1
                ];
                if (!meus.isEmpty() && String.isNotBlank(meus[0].ContactId)) {
                    resolvedContactId = meus[0].ContactId;
                }
            }

            if (String.isBlank(resolvedContactId)) {
                results.add(dto);
                continue;
            }
            // Experience Cloud person account sites pass Account ID (001...) via
            // @MessagingEndUser.ContactId; fall back to AccountId lookup in that case.
            String idPrefix = resolvedContactId.left(3);
            List<Contact> contacts;
            if (idPrefix == '001') {
                contacts = [
                    SELECT FirstName, LastName, Loyalty_Tier__c, Email
                    FROM Contact
                    WHERE AccountId = :resolvedContactId
                    LIMIT 1
                ];
            } else {
                contacts = [
                    SELECT FirstName, LastName, Loyalty_Tier__c, Email
                    FROM Contact
                    WHERE Id = :resolvedContactId
                    LIMIT 1
                ];
            }
            if (!contacts.isEmpty()) {
                Contact c = contacts[0];
                dto.firstName    = c.FirstName != null  ? c.FirstName  : '';
                dto.lastName     = c.LastName  != null  ? c.LastName   : '';
                dto.loyaltyTier  = c.Loyalty_Tier__c != null ? c.Loyalty_Tier__c : '';
                dto.email        = c.Email     != null  ? c.Email      : '';
                dto.profileFound = String.isNotBlank(c.Email);
            }
            results.add(dto);
        }
        return results;
    }

    public class ContactRequest {
        @InvocableVariable(required=false label='Contact Id') public String contactId;
        @InvocableVariable(required=false label='Messaging End User Id') public String endUserId;
    }

    public class ContactProfileDTO {
        @InvocableVariable public String  firstName;
        @InvocableVariable public String  lastName;
        @InvocableVariable public String  loyaltyTier;
        @InvocableVariable public String  email;
        @InvocableVariable public Boolean profileFound;
    }
}