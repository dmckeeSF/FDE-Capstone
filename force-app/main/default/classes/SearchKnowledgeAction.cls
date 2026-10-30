public without sharing class SearchKnowledgeAction {

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
            results.add(runSearch(req));
        }
        return results;
    }

    private static SearchResult runSearch(SearchRequest req) {
        SearchResult res = new SearchResult();
        res.articleFound = false;
        res.articleTitle = '';
        res.articleContent = '';

        if (String.isBlank(req.searchQuery)) {
            return res;
        }

        // Use SOSL for full-text search — handles natural language queries, partial
        // matches, and searches across Title, Summary, and Detail__c automatically.
        // Phrase search first; fall back to tokenized if no hits.
        String cleanQuery = req.searchQuery.replaceAll('[^a-zA-Z0-9 \'-]', ' ').trim();
        List<Knowledge__kav> hits = soslSearch('"' + cleanQuery + '"');
        if (hits.isEmpty()) {
            hits = soslSearch(cleanQuery);
        }

        if (hits.isEmpty()) {
            return res;
        }

        // Concatenate up to 3 articles so the agent can present a list
        List<String> titles = new List<String>();
        List<String> contents = new List<String>();
        for (Integer i = 0; i < Math.min(3, hits.size()); i++) {
            Knowledge__kav art = hits[i];
            titles.add(art.Title);
            String body = art.Detail__c != null ? art.Detail__c : art.Summary;
            if (body != null) {
                body = body.replaceAll('<[^>]+>', '').trim();
                if (body.length() > 1500) {
                    body = body.substring(0, 1500) + '...';
                }
                contents.add('=== ' + art.Title + ' ===\n' + body);
            }
        }

        res.articleFound   = true;
        res.articleTitle   = String.join(titles, '\n');
        res.articleContent = String.join(contents, '\n\n');
        return res;
    }

    private static List<Knowledge__kav> soslSearch(String term) {
        try {
            List<List<SObject>> raw = Search.query(
                'FIND {' + String.escapeSingleQuotes(term) + '} IN ALL FIELDS RETURNING ' +
                'Knowledge__kav(Title, Detail__c, Summary ' +
                'WHERE PublishStatus = \'Online\' AND Language = \'en_US\') LIMIT 5'
            );
            return (List<Knowledge__kav>) raw[0];
        } catch (Exception e) {
            return new List<Knowledge__kav>();
        }
    }
}