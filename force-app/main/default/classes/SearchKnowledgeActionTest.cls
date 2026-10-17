@IsTest
private class SearchKnowledgeActionTest {

    @TestSetup
    static void setup() {
        Knowledge__kav art = new Knowledge__kav(
            Title = 'Test Cancellation Policy',
            UrlName = 'test-cancellation-policy-' + String.valueOf(Datetime.now().getTime()),
            Language = 'en_US',
            Summary = 'Test cancellation rules',
            Detail__c = 'You may cancel free of charge up to 24 hours before your reservation.'
        );
        insert art;
        // Re-query to get KnowledgeArticleId — not populated on the insert-returned object
        art = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE Id = :art.Id LIMIT 1];
        KbManagement.PublishingService.publishArticle(art.KnowledgeArticleId, true);
    }

    @IsTest
    static void testSearchFindsArticle() {
        SearchKnowledgeAction.SearchRequest req = new SearchKnowledgeAction.SearchRequest();
        req.searchQuery = 'cancellation';
        List<SearchKnowledgeAction.SearchResult> results = SearchKnowledgeAction.searchKnowledge(
            new List<SearchKnowledgeAction.SearchRequest>{ req }
        );
        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].articleFound, 'Should find cancellation article');
        System.assertNotEquals('', results[0].articleTitle, 'Title should not be empty');
    }

    @IsTest
    static void testSearchNoMatch() {
        SearchKnowledgeAction.SearchRequest req = new SearchKnowledgeAction.SearchRequest();
        req.searchQuery = 'xyznonexistentterm12345';
        List<SearchKnowledgeAction.SearchResult> results = SearchKnowledgeAction.searchKnowledge(
            new List<SearchKnowledgeAction.SearchRequest>{ req }
        );
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].articleFound, 'Should not find article');
    }

    @IsTest
    static void testBlankQuery() {
        SearchKnowledgeAction.SearchRequest req = new SearchKnowledgeAction.SearchRequest();
        req.searchQuery = '';
        List<SearchKnowledgeAction.SearchResult> results = SearchKnowledgeAction.searchKnowledge(
            new List<SearchKnowledgeAction.SearchRequest>{ req }
        );
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].articleFound);
    }

    @IsTest
    static void testWithDataCategory() {
        SearchKnowledgeAction.SearchRequest req = new SearchKnowledgeAction.SearchRequest();
        req.searchQuery = 'cancellation';
        req.dataCategory = 'CancellationPolicy';
        List<SearchKnowledgeAction.SearchResult> results = SearchKnowledgeAction.searchKnowledge(
            new List<SearchKnowledgeAction.SearchRequest>{ req }
        );
        System.assertEquals(1, results.size());
        // dataCategory is informational — search still runs
    }
}