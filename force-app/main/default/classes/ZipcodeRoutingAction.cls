/**
 * ZipcodeRoutingAction
 * Resolves an Omni-Channel queue for inbound diner support based on the
 * contact's billing/mailing zipcode. Within each queue, Omni-Channel's
 * built-in round-robin handles agent assignment — we only determine WHICH
 * queue to route to here.
 *
 * Queue mapping is stored as Custom Metadata (Zipcode_Queue_Mapping__mdt)
 * so it can be updated without a code deployment.
 * Falls back to the default queue when no matching mapping exists.
 */
public with sharing class ZipcodeRoutingAction {

    @InvocableMethod(
        label='Resolve Queue by Zipcode'
        description='Returns the Omni-Channel queue developer name for the contact zipcode'
    )
    public static List<RoutingResult> resolveQueue(List<RoutingRequest> requests) {
        // Collect all unique zipcodes in one pass
        Set<String> zips = new Set<String>();
        for (RoutingRequest req : requests) {
            if (String.isNotBlank(req.zipcode)) zips.add(req.zipcode.trim());
        }

        // Single SOQL for all matching metadata records
        Map<String, String> queueByZip = new Map<String, String>();
        String defaultQueue = 'Diner_Support_General';
        for (Zipcode_Queue_Mapping__mdt m : [
            SELECT Zipcode__c, Queue_Developer_Name__c, Is_Default__c
            FROM Zipcode_Queue_Mapping__mdt
            WHERE Zipcode__c IN :zips
               OR Is_Default__c = true
        ]) {
            if (m.Is_Default__c) {
                defaultQueue = m.Queue_Developer_Name__c;
            } else {
                queueByZip.put(m.Zipcode__c, m.Queue_Developer_Name__c);
            }
        }

        List<RoutingResult> results = new List<RoutingResult>();
        for (RoutingRequest req : requests) {
            RoutingResult res = new RoutingResult();
            String zip = String.isNotBlank(req.zipcode) ? req.zipcode.trim() : '';
            res.queueDeveloperName = queueByZip.containsKey(zip)
                ? queueByZip.get(zip)
                : defaultQueue;
            res.zipcode = zip;
            results.add(res);
        }
        return results;
    }

    public class RoutingRequest {
        @InvocableVariable(required=true label='Contact Zipcode')
        public String zipcode;
    }

    public class RoutingResult {
        @InvocableVariable(label='Queue Developer Name')
        public String queueDeveloperName;

        @InvocableVariable(label='Zipcode Used')
        public String zipcode;
    }
}
