@IsTest
private class GetCurrentUserContactIdTest {

    @IsTest
    static void testInternalUserReturnsNull() {
        // Running user in an Apex test is an internal admin — ContactId is null
        Test.startTest();
        String contactId = GetCurrentUserContactId.getContactId();
        Test.stopTest();

        System.assertEquals(null, contactId, 'Internal user should return null ContactId');
    }

    @IsTest
    static void testMethodIsCallable() {
        // Verify the method exists and executes without exceptions
        Boolean threw = false;
        try {
            GetCurrentUserContactId.getContactId();
        } catch (Exception e) {
            threw = true;
        }
        System.assertEquals(false, threw, 'getContactId() should not throw');
    }
}
