public with sharing class SearchKnowledgeAction {

    public class SearchRequest {
        @InvocableVariable(label='Search Query' description='The search query from the diner' required=true)
        public String searchQuery;

        @InvocableVariable(label='Data Category' description='Knowledge data category scope')
        public String dataCategory;
    }

    public class SearchResult {
        @InvocableVariable(label='Article Title')
        public String articleTitle;

        @InvocableVariable(label='Article Content')
        public String articleContent;

        @InvocableVariable(label='Article Found')
        public Boolean articleFound;
    }

    @InvocableMethod(label='Search Knowledge Articles' description='Search Salesforce Knowledge for FAQ and policy articles')
    public static List<SearchResult> searchKnowledge(List<SearchRequest> requests) {
        List<SearchResult> results = new List<SearchResult>();
        for (SearchRequest req : requests) {
            results.add(doSearch(req));
        }
        return results;
    }

    private static SearchResult doSearch(SearchRequest req) {
        SearchResult res = new SearchResult();
        res.articleFound = false;

        if (String.isBlank(req.searchQuery)) {
            res.articleTitle = '';
            res.articleContent = '';
            return res;
        }

        String query = '%' + String.escapeSingleQuotes(req.searchQuery) + '%';

        // SOQL LIKE search on Title and Summary (Rich Text fields cannot be filtered)
        // Detail__c is selected for the response body
        List<Knowledge__kav> articles = [
            SELECT Title, Detail__c, Summary
            FROM Knowledge__kav
            WHERE PublishStatus = 'Online'
            AND Language = 'en_US'
            AND (Title LIKE :query OR Summary LIKE :query)
            ORDER BY ArticleTotalViewCount DESC NULLS LAST
            LIMIT 1
        ];

        if (!articles.isEmpty()) {
            Knowledge__kav art = articles[0];
            res.articleFound = true;
            res.articleTitle = art.Title;
            // Strip HTML tags from Rich Text for clean agent response
            String content = art.Detail__c != null ? art.Detail__c : art.Summary;
            res.articleContent = content != null ? content.replaceAll('<[^>]+>', '').trim() : '';
            if (res.articleContent.length() > 2000) {
                res.articleContent = res.articleContent.substring(0, 2000) + '...';
            }
        } else {
            res.articleTitle = '';
            res.articleContent = '';
        }
        return res;
    }
}