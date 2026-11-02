public without sharing class SendPasswordResetAction {

    @InvocableMethod(label='Send Password Reset' description='Sends a password reset email to the verified diner')
    public static List<PasswordResetResult> execute(List<PasswordResetRequest> requests) {
        List<PasswordResetResult> results = new List<PasswordResetResult>();
        for (PasswordResetRequest req : requests) {
            PasswordResetResult res = new PasswordResetResult();
            try {
                if (String.isBlank(req.contactId)) {
                    res.isSuccess = false;
                    res.errorMessage = 'Contact ID is required.';
                    results.add(res);
                    continue;
                }
                List<User> users = [
                    SELECT Id, Username
                    FROM User
                    WHERE ContactId = :req.contactId
                      AND IsActive = true
                    LIMIT 1
                ];
                if (users.isEmpty()) {
                    res.isSuccess = false;
                    res.errorMessage = 'No active portal user found for this contact.';
                    results.add(res);
                    continue;
                }
                System.resetPassword(users[0].Id, true);
                res.isSuccess = true;
                res.confirmationMessage = 'A password reset email has been sent to the email address on file.';
            } catch (Exception e) {
                res.isSuccess = false;
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    public class PasswordResetRequest {
        @InvocableVariable(required=true label='Contact Id') public String contactId;
    }

    public class PasswordResetResult {
        @InvocableVariable public Boolean isSuccess;
        @InvocableVariable public String  confirmationMessage;
        @InvocableVariable public String  errorMessage;
    }
}
