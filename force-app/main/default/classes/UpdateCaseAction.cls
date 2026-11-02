public without sharing class UpdateCaseAction {

    @InvocableMethod(label='Update Case' description='Adds a comment to an existing support Case')
    public static List<UpdateCaseResult> execute(List<UpdateCaseRequest> requests) {
        List<UpdateCaseResult> results = new List<UpdateCaseResult>();
        for (UpdateCaseRequest req : requests) {
            UpdateCaseResult res = new UpdateCaseResult();
            try {
                if (String.isBlank(req.caseId) || String.isBlank(req.comment)) {
                    res.isSuccess = false;
                    res.errorMessage = 'Case ID and comment are required.';
                    results.add(res);
                    continue;
                }
                CaseComment cc = new CaseComment(
                    ParentId = req.caseId,
                    CommentBody = req.comment,
                    IsPublished = true
                );
                insert cc;
                res.isSuccess = true;
                res.confirmationMessage = 'Your comment has been added to the case.';
            } catch (Exception e) {
                res.isSuccess = false;
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    public class UpdateCaseRequest {
        @InvocableVariable(required=true  label='Case Id')  public String caseId;
        @InvocableVariable(required=true  label='Comment')  public String comment;
    }

    public class UpdateCaseResult {
        @InvocableVariable public Boolean isSuccess;
        @InvocableVariable public String  confirmationMessage;
        @InvocableVariable public String  errorMessage;
    }
}
