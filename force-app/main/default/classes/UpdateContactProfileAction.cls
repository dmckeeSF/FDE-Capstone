public without sharing class UpdateContactProfileAction {

    @InvocableMethod(label='Update Contact Profile' description='Updates a single field on the verified diner Contact record')
    public static List<UpdateContactResult> execute(List<UpdateContactRequest> requests) {
        List<UpdateContactResult> results = new List<UpdateContactResult>();
        for (UpdateContactRequest req : requests) {
            UpdateContactResult res = new UpdateContactResult();
            try {
                if (String.isBlank(req.contactId) || String.isBlank(req.fieldName) || String.isBlank(req.newValue)) {
                    res.isSuccess = false;
                    res.errorMessage = 'Contact ID, field name, and new value are required.';
                    results.add(res);
                    continue;
                }
                Map<String, Object> fieldMap = new Map<String, Object>{ req.fieldName => req.newValue };
                Contact c = new Contact(Id = req.contactId);
                c.put(req.fieldName, req.newValue);
                update c;
                res.isSuccess = true;
                res.confirmationMessage = req.fieldName + ' has been updated successfully.';
            } catch (Exception e) {
                res.isSuccess = false;
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    public class UpdateContactRequest {
        @InvocableVariable(required=true  label='Contact Id')   public String contactId;
        @InvocableVariable(required=true  label='Field Name')   public String fieldName;
        @InvocableVariable(required=true  label='New Value')    public String newValue;
    }

    public class UpdateContactResult {
        @InvocableVariable public Boolean isSuccess;
        @InvocableVariable public String  confirmationMessage;
        @InvocableVariable public String  errorMessage;
    }
}
