public with sharing class GenerateCaseSummaryAction {

    public class Request {
        @InvocableVariable(label='Case Id' required=true)
        public String caseId;
    }

    public class Response {
        @InvocableVariable(label='Generated Summary')
        public String summary;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Generate Case Summary'
        description='Builds a structured handoff note for the escalation case and writes it to Case.Description'
    )
    public static List<Response> generate(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) {
            results.add(generateSummary(req.caseId));
        }
        return results;
    }

    private static Response generateSummary(String caseId) {
        Response res = new Response();
        try {
            Case c = [
                SELECT Id, CaseNumber, Subject,
                       Issue_Classification__c,
                       Contact.FirstName, Contact.LastName, Contact.Email
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            String summary = buildStructuredSummary(c);
            update new Case(Id = caseId, Description = summary);
            res.summary   = summary;
            res.isSuccess = true;

        } catch (Exception e) {
            res.summary      = '';
            res.isSuccess    = false;
            res.errorMessage = e.getMessage();
        }
        return res;
    }

    private static String buildStructuredSummary(Case c) {
        String dinerName = '';
        String dinerEmail = '';
        if (c.Contact != null) {
            dinerName  = ((c.Contact.FirstName != null ? c.Contact.FirstName : '') + ' ' +
                          (c.Contact.LastName  != null ? c.Contact.LastName  : '')).trim();
            dinerEmail = c.Contact.Email != null ? c.Contact.Email : '';
        }

        String classification = c.Issue_Classification__c != null ? c.Issue_Classification__c : 'General Inquiry';

        return '--- ARIA ESCALATION HANDOFF ---\n' +
               'Case #: ' + c.CaseNumber + '\n' +
               'Subject: ' + (c.Subject != null ? c.Subject : '') + '\n' +
               (String.isNotBlank(dinerName)  ? 'Diner: '  + dinerName  + '\n' : '') +
               (String.isNotBlank(dinerEmail) ? 'Email: '  + dinerEmail + '\n' : '') +
               'Classification: ' + classification;
    }
}
