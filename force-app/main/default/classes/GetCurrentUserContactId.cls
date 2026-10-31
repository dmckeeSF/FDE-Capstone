public without sharing class GetCurrentUserContactId {

    @AuraEnabled(cacheable=true)
    public static String getContactId() {
        List<User> users = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (!users.isEmpty() && users[0].ContactId != null) {
            return users[0].ContactId;
        }
        return null;
    }
}
