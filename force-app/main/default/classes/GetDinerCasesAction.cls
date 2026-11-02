public without sharing class GetDinerCasesAction {

    @InvocableMethod(label='Get Diner Cases' description='Returns open and recent support cases for the verified diner')
    public static List<CaseListResult> execute(List<CaseListRequest> requests) {
        List<CaseListResult> results = new List<CaseListResult>();
        for (CaseListRequest req : requests) {
            CaseListResult res = new CaseListResult();
            if (String.isBlank(req.contactId)) {
                res.caseSummaries = '';
                res.caseCount = 0;
                results.add(res);
                continue;
            }
            List<Case> cases = [
                SELECT CaseNumber, Subject, Status, LastModifiedDate
                FROM Case
                WHERE ContactId = :req.contactId
                ORDER BY LastModifiedDate DESC
                LIMIT 20
            ];
            res.caseCount = cases.size();
            List<String> summaries = new List<String>();
            for (Case c : cases) {
                summaries.add(
                    c.Id + '|' +
                    c.CaseNumber + '|' +
                    (c.Subject != null ? c.Subject : '') + '|' +
                    c.Status + '|' +
                    String.valueOf(c.LastModifiedDate)
                );
            }
            res.caseSummaries = String.join(summaries, '\n');
            results.add(res);
        }
        return results;
    }

    public class CaseListRequest {
        @InvocableVariable(required=true label='Contact Id') public String contactId;
    }

    public class CaseListResult {
        @InvocableVariable public String  caseSummaries;
        @InvocableVariable public Integer caseCount;
        @InvocableVariable public String  errorMessage;
    }
}
