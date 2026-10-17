@IsTest
private class ReservationMockApiControllerTest {

    // ── test data factory ────────────────────────────────────────────────────

    private static Account createRestaurant() {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Account' AND DeveloperName = 'Restaurant'
            LIMIT 1
        ];
        Account a = new Account(Name = 'Test Bistro');
        if (!rts.isEmpty()) {
            a.RecordTypeId = rts[0].Id;
        }
        insert a;
        return a;
    }

    private static Contact createDiner() {
        Contact c = new Contact(
            FirstName = 'Jane',
            LastName  = 'Diner'
        );
        insert c;
        return c;
    }

    private static Reservation__c createReservation(Id restaurantId, Id dinerId) {
        Reservation__c r = new Reservation__c(
            Restaurant__c        = restaurantId,
            Diner__c             = dinerId,
            Reservation_Date__c  = Date.today().addDays(7),
            Reservation_Time__c  = Time.newInstance(19, 0, 0, 0),
            Party_Size__c        = 2,
            Status__c            = 'Confirmed',
            Special_Requests__c  = 'Window seat please'
        );
        insert r;
        return r;
    }

    // ── GET: found ───────────────────────────────────────────────────────────

    @IsTest
    static void testGet_found() {
        Account restaurant = createRestaurant();
        Contact diner      = createDiner();
        Reservation__c res = createReservation(restaurant.Id, diner.Id);

        // Read back to get the auto-number booking reference
        res = [SELECT Booking_Reference__c FROM Reservation__c WHERE Id = :res.Id];

        RestRequest req = new RestRequest();
        req.httpMethod  = 'GET';
        req.requestURI  = '/services/apexrest/reservations/' + res.Booking_Reference__c;
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ReservationMockApiController.doGet();
        Test.stopTest();

        RestResponse resp = RestContext.response;
        System.assertEquals(200, resp.statusCode, 'Expected HTTP 200');
        Map<String, Object> body =
            (Map<String, Object>) JSON.deserializeUntyped(resp.responseBody.toString());
        System.assertEquals(res.Booking_Reference__c, body.get('bookingReference'),
            'bookingReference mismatch');
        System.assertEquals('Confirmed', body.get('status'), 'status mismatch');
        System.assertEquals('Test Bistro', body.get('restaurantName'), 'restaurantName mismatch');
        System.assertEquals('Jane Diner', body.get('dinerName'), 'dinerName mismatch');
        System.assertEquals(2, body.get('partySize'), 'partySize mismatch');
    }

    // ── GET: not found ───────────────────────────────────────────────────────

    @IsTest
    static void testGet_notFound() {
        RestRequest req = new RestRequest();
        req.httpMethod  = 'GET';
        req.requestURI  = '/services/apexrest/reservations/RES-DOES-NOT-EXIST';
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ReservationMockApiController.doGet();
        Test.stopTest();

        RestResponse resp = RestContext.response;
        System.assertEquals(404, resp.statusCode, 'Expected HTTP 404');
        Map<String, Object> body =
            (Map<String, Object>) JSON.deserializeUntyped(resp.responseBody.toString());
        System.assertEquals('Reservation not found', body.get('error'), 'error message mismatch');
    }

    // ── PATCH: modify reservation ─────────────────────────────────────────────

    @IsTest
    static void testPatch_modifyReservation() {
        Account restaurant = createRestaurant();
        Contact diner      = createDiner();
        Reservation__c res = createReservation(restaurant.Id, diner.Id);
        res = [SELECT Booking_Reference__c, Reservation_Date__c
               FROM Reservation__c WHERE Id = :res.Id];

        Date newDate = Date.today().addDays(14);
        Map<String, Object> patchBody = new Map<String, Object>{
            'newDate'      => String.valueOf(newDate),
            'newTime'      => '20:30',
            'newPartySize' => 4
        };

        RestRequest req = new RestRequest();
        req.httpMethod   = 'PATCH';
        req.requestURI   = '/services/apexrest/reservations/' + res.Booking_Reference__c;
        req.requestBody  = Blob.valueOf(JSON.serialize(patchBody));
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ReservationMockApiController.doPatch();
        Test.stopTest();

        RestResponse resp = RestContext.response;
        System.assertEquals(200, resp.statusCode, 'Expected HTTP 200');
        Map<String, Object> body =
            (Map<String, Object>) JSON.deserializeUntyped(resp.responseBody.toString());
        System.assertEquals('Modified', body.get('status'), 'status should be Modified');
        System.assertEquals(4, body.get('partySize'), 'partySize should be 4');
        System.assertEquals(String.valueOf(newDate), body.get('date'), 'date mismatch');

        // Verify DB fields
        Reservation__c updated = [
            SELECT Status__c, Party_Size__c, Modified_At__c, Original_Reservation_Date__c
            FROM Reservation__c WHERE Id = :res.Id
        ];
        System.assertEquals('Modified', updated.Status__c);
        System.assertEquals(4, (Integer) updated.Party_Size__c);
        System.assertNotEquals(null, updated.Modified_At__c, 'Modified_At__c should be set');
        System.assertEquals(res.Reservation_Date__c, updated.Original_Reservation_Date__c,
            'Original_Reservation_Date__c should preserve old date');
    }

    // ── PATCH: not found ──────────────────────────────────────────────────────

    @IsTest
    static void testPatch_notFound() {
        Map<String, Object> patchBody = new Map<String, Object>{
            'newDate' => String.valueOf(Date.today().addDays(7))
        };

        RestRequest req = new RestRequest();
        req.httpMethod  = 'PATCH';
        req.requestURI  = '/services/apexrest/reservations/RES-DOES-NOT-EXIST';
        req.requestBody = Blob.valueOf(JSON.serialize(patchBody));
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ReservationMockApiController.doPatch();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode, 'Expected HTTP 404');
    }

    // ── DELETE: cancel with reason ────────────────────────────────────────────

    @IsTest
    static void testDelete_withReason() {
        Account restaurant = createRestaurant();
        Contact diner      = createDiner();
        Reservation__c res = createReservation(restaurant.Id, diner.Id);
        res = [SELECT Booking_Reference__c FROM Reservation__c WHERE Id = :res.Id];

        Map<String, Object> deleteBody = new Map<String, Object>{
            'cancellationReason' => 'Change of Plans'
        };

        RestRequest req = new RestRequest();
        req.httpMethod  = 'DELETE';
        req.requestURI  = '/services/apexrest/reservations/' + res.Booking_Reference__c;
        req.requestBody = Blob.valueOf(JSON.serialize(deleteBody));
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ReservationMockApiController.doDelete();
        Test.stopTest();

        RestResponse resp = RestContext.response;
        System.assertEquals(200, resp.statusCode, 'Expected HTTP 200');
        Map<String, Object> body =
            (Map<String, Object>) JSON.deserializeUntyped(resp.responseBody.toString());
        System.assertEquals(res.Booking_Reference__c, body.get('bookingReference'));
        System.assertEquals('Cancelled', body.get('status'));
        System.assertNotEquals(null, body.get('cancelledAt'), 'cancelledAt should be present');

        Reservation__c updated = [
            SELECT Status__c, Cancelled_At__c, Cancellation_Reason__c
            FROM Reservation__c WHERE Id = :res.Id
        ];
        System.assertEquals('Cancelled', updated.Status__c);
        System.assertNotEquals(null, updated.Cancelled_At__c);
        System.assertEquals('Change of Plans', updated.Cancellation_Reason__c);
    }

    // ── DELETE: without reason body ───────────────────────────────────────────

    @IsTest
    static void testDelete_noBody() {
        Account restaurant = createRestaurant();
        Contact diner      = createDiner();
        Reservation__c res = createReservation(restaurant.Id, diner.Id);
        res = [SELECT Booking_Reference__c FROM Reservation__c WHERE Id = :res.Id];

        RestRequest req = new RestRequest();
        req.httpMethod = 'DELETE';
        req.requestURI = '/services/apexrest/reservations/' + res.Booking_Reference__c;
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ReservationMockApiController.doDelete();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Expected HTTP 200');
        Reservation__c updated = [SELECT Status__c FROM Reservation__c WHERE Id = :res.Id];
        System.assertEquals('Cancelled', updated.Status__c);
    }

    // ── DELETE: not found ─────────────────────────────────────────────────────

    @IsTest
    static void testDelete_notFound() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'DELETE';
        req.requestURI = '/services/apexrest/reservations/RES-DOES-NOT-EXIST';
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ReservationMockApiController.doDelete();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode, 'Expected HTTP 404');
    }
}