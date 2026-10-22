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
        description='Calls the Aria_Escalation_Case_Summary prompt template and returns the generated handoff note'
        callout=true
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
                SELECT Id, CaseNumber, Subject, Description,
                       Issue_Classification__c, Conversation_Transcript__c,
                       Contact.FirstName, Contact.LastName
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            String caseContext = buildCaseContext(c);
            String classification = c.Issue_Classification__c != null ? c.Issue_Classification__c : 'General Inquiry';
            String transcript    = c.Conversation_Transcript__c != null ? c.Conversation_Transcript__c : '(no transcript available)';

            ConnectApi.EinsteinPromptTemplateGenerationsInput input =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            input.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
            input.isPreview = false;

            Map<String, ConnectApi.WrappedValue> valueMap = new Map<String, ConnectApi.WrappedValue>();

            ConnectApi.WrappedValue ctxVal = new ConnectApi.WrappedValue();
            ctxVal.value = caseContext;
            valueMap.put('Input:CaseContext', ctxVal);

            ConnectApi.WrappedValue classVal = new ConnectApi.WrappedValue();
            classVal.value = classification;
            valueMap.put('Input:IssueClassification', classVal);

            ConnectApi.WrappedValue txVal = new ConnectApi.WrappedValue();
            txVal.value = transcript;
            valueMap.put('Input:Transcript', txVal);

            input.inputParams = valueMap;

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    'Aria_Escalation_Case_Summary', input
                );

            if (response != null && response.generations != null && !response.generations.isEmpty()) {
                res.summary   = response.generations[0].text;
                res.isSuccess = true;
            } else {
                res.summary      = '';
                res.isSuccess    = false;
                res.errorMessage = 'No generations returned from prompt template';
            }
        } catch (Exception e) {
            res.summary      = '';
            res.isSuccess    = false;
            res.errorMessage = e.getMessage();
        }
        return res;
    }

    private static String buildCaseContext(Case c) {
        String dinerName = '';
        if (c.Contact != null) {
            dinerName = ((c.Contact.FirstName != null ? c.Contact.FirstName : '') + ' ' +
                        (c.Contact.LastName  != null ? c.Contact.LastName  : '')).trim();
        }
        return 'Case #: ' + c.CaseNumber + '\n' +
               'Subject: ' + (c.Subject != null ? c.Subject : '') + '\n' +
               (String.isNotBlank(dinerName) ? 'Diner: ' + dinerName + '\n' : '');
    }
}
