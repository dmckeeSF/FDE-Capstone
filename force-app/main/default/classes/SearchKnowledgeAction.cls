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
        // Collect all non-blank queries and run one SOQL with OR conditions
        List<String> queries = new List<String>();
        for (SearchRequest req : requests) {
            if (String.isNotBlank(req.searchQuery)) {
                queries.add('%' + String.escapeSingleQuotes(req.searchQuery) + '%');
            }
        }

        // Single SOQL: fetch top articles matching any of the query terms
        Map<String, Knowledge__kav> bestByQuery = new Map<String, Knowledge__kav>();
        if (!queries.isEmpty()) {
            // Build one query per unique search term using a Map to deduplicate
            // SOQL doesn't support dynamic OR across variable lists, so we
            // query the broadest set and match in Apex to stay within 1 SOQL.
            Set<String> querySet = new Set<String>(queries);
            List<Knowledge__kav> articles = [
                SELECT Title, Detail__c, Summary
                FROM Knowledge__kav
                WHERE PublishStatus = 'Online'
                  AND Language = 'en_US'
                ORDER BY ArticleTotalViewCount DESC NULLS LAST
                LIMIT 200
            ];

            // Match each article to the best query term
            for (String q : querySet) {
                String term = q.replace('%', '').toLowerCase();
                for (Knowledge__kav art : articles) {
                    if ((art.Title != null && art.Title.toLowerCase().contains(term))
                        || (art.Summary != null && art.Summary.toLowerCase().contains(term))) {
                        bestByQuery.put(q, art);
                        break; // articles are sorted by view count; first match wins
                    }
                }
            }
        }

        List<SearchResult> results = new List<SearchResult>();
        for (SearchRequest req : requests) {
            SearchResult res = new SearchResult();
            res.articleFound = false;

            if (String.isBlank(req.searchQuery)) {
                res.articleTitle   = '';
                res.articleContent = '';
                results.add(res);
                continue;
            }

            String queryKey = '%' + String.escapeSingleQuotes(req.searchQuery) + '%';
            Knowledge__kav art = bestByQuery.get(queryKey);

            if (art != null) {
                res.articleFound = true;
                res.articleTitle = art.Title;
                String content = art.Detail__c != null ? art.Detail__c : art.Summary;
                res.articleContent = content != null ? content.replaceAll('<[^>]+>', '').trim() : '';
                if (res.articleContent.length() > 2000) {
                    res.articleContent = res.articleContent.substring(0, 2000) + '...';
                }
            } else {
                res.articleTitle   = '';
                res.articleContent = '';
            }
            results.add(res);
        }
        return results;
    }
}
