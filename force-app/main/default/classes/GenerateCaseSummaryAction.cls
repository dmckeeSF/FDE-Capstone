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
            ConnectApi.EinsteinPromptTemplateGenerationsInput input =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();

            input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            input.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
            input.isPreview = false;

            Map<String, ConnectApi.WrappedValue> valueMap = new Map<String, ConnectApi.WrappedValue>();
            ConnectApi.WrappedValue caseValue = new ConnectApi.WrappedValue();
            caseValue.value = caseId;
            valueMap.put('Input:Case', caseValue);
            input.inputParams = valueMap;

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    'Aria_Escalation_Case_Summary', input
                );

            if (response != null && response.generations != null && !response.generations.isEmpty()) {
                res.summary = response.generations[0].text;
                res.isSuccess = true;
            } else {
                res.summary = '';
                res.isSuccess = false;
                res.errorMessage = 'No generations returned from prompt template';
            }
        } catch (Exception e) {
            res.summary = '';
            res.isSuccess = false;
            res.errorMessage = e.getMessage();
        }
        return res;
    }
}
