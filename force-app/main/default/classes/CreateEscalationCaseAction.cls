public without sharing class CreateEscalationCaseAction {

    @InvocableMethod(label='Create Escalation Case' description='Creates a Case record to log a diner escalation before warm transfer to a human agent')
    public static List<EscalationResult> execute(List<EscalationRequest> requests) {
        List<EscalationResult> results = new List<EscalationResult>();
        for (EscalationRequest req : requests) {
            EscalationResult res = new EscalationResult();
            try {
                Case c = new Case(
                    Subject = 'Diner Escalation — ' + (String.isBlank(req.issueSummary) ? 'No summary provided' : req.issueSummary),
                    Description = req.issueSummary,
                    Origin = 'Chat',
                    Status = 'New'
                );
                if (String.isNotBlank(req.contactId)) {
                    c.ContactId = req.contactId;
                }
                insert c;
                res.caseId = c.Id;
                res.caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :c.Id LIMIT 1].CaseNumber;
                res.isSuccess = true;
            } catch (Exception e) {
                res.isSuccess = false;
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    public class EscalationRequest {
        @InvocableVariable(required=false label='Contact Id') public String contactId;
        @InvocableVariable(required=true  label='Issue Summary') public String issueSummary;
    }

    public class EscalationResult {
        @InvocableVariable public String  caseId;
        @InvocableVariable public String  caseNumber;
        @InvocableVariable public Boolean isSuccess;
        @InvocableVariable public String  errorMessage;
    }
}
