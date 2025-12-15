@IsTest
private class shipmentRP_Test {

    private class FV_Mock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            String url = req.getEndpoint().toLowerCase();

            if (url.contains('?returnquotes=true')) {
                HttpResponse r = new HttpResponse();
                r.setStatusCode(200);
                r.setBody(
                    '{"shipmentId":"SHIP123","quotes":[' +
                    '{"status":"active","mode":"ltl","assetCarrierName":"TestCarrier","serviceDescription":"STD","amount":120.5,"currency":"USD","quoteId":"Q123"}]}'
                );
                return r;
            }

            if (url.endsWith('/book')) {
                HttpResponse r = new HttpResponse();
                r.setStatusCode(200);
                r.setBody(
                    '{ "shipmentId":"SHIP123","status":"confirmed",' +
                    '"selectedQuote":{"amount":120.5,"currency":"USD","assetCarrierName":"TestCarrier","serviceDescription":"STD"},' +
                    '"documents":[{"fileName":"BOL.pdf","downloadUrl":"https://mock.com/bol"}] }'
                );
                return r;
            }

            HttpResponse pdf = new HttpResponse();
            pdf.setStatusCode(200);
            pdf.setBodyAsBlob(Blob.valueOf('PDF'));
            return pdf;
        }
    }

    private class BookingErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = new HttpResponse();
            String url = req.getEndpoint().toLowerCase();
            if (url.contains('/shipments/ltl/') && url.endsWith('/book')) {
                r.setStatusCode(400);
                r.setBody('{ "message": "Bad Request", "errors":[{"message":"Invalid"}] }');
            } else {
                r.setStatusCode(200);
                r.setBody('OK');
            }
            return r;
        }
    }

    private class BlobNullMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = new HttpResponse();
            String url = req.getEndpoint().toLowerCase();
            if (url.contains('/bol') || url.contains('/label')) {
                r.setStatusCode(200);
                r.setBodyAsBlob(null);
            } else {
                r.setStatusCode(200);
                r.setBody('OK');
            }
            return r;
        }
    }

    private static Logistic__c seed() {
        Account a = new Account(Name = 'A');
        insert a;
        Contact c = new Contact(LastName = 'L', AccountId = a.Id);
        insert c;
        Address__c f = new Address__c(
            Name = 'FA',
            City__c = 'C1',
            State__c = 'S1',
            Country__c = 'United States',
            Postal_Code__c = '1',
            Contact__c = c.Id,
            Customer__c = a.Id
        );
        insert f;
        Address__c t = new Address__c(
            Name = 'TA',
            City__c = 'C2',
            State__c = 'S2',
            Country__c = 'United States',
            Postal_Code__c = '2',
            Contact__c = c.Id,
            Customer__c = a.Id
        );
        insert t;
        Logistic__c lg = new Logistic__c(
            Name = 'LG',
            Account__c = a.Id,
            From_Address__c = f.Id,
            To_Address__c = t.Id,
            Contact__c = c.Id,
            From_Contact__c = c.Id,
            Billing_Options__c = 'SENDER'
        );
        insert lg;
        return lg;
    }

    @IsTest
    static void test_Full_FreightView_Flow() {
        Credentials__c cred = new Credentials__c(
            Name = System.Label.AxoltFreightViewERP,
            URL__c = 'https://mock.com',
            Username_Login__c = 'u',
            Password_Transkey__c = 'p'
        );
        insert cred;

        Logistic__c lg = seed();
        shipmentRP.PackageInputWrapper pi = new shipmentRP.PackageInputWrapper();
        pi.FVPackageType = 'Box';
        pi.Weight = 50;
        List<shipmentRP.PackageInputWrapper> pkg = new List<shipmentRP.PackageInputWrapper>{ pi };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FV_Mock());

        List<shipmentRP.quoteWrapper> rates = shipmentRP.getRatesFV(
            pkg,
            lg.From_Address__r,
            lg.To_Address__r,
            true,
            '2025-12-01',
            cred,
            '{}',
            '{}'
        );
        System.assert(!rates.isEmpty());

        shipmentRP.BookingResult book = shipmentRP.bookSelectedQuote(
            'freightview',
            'Q123',
            'SHIP123',
            true,
            'ltl',
            JSON.serialize(lg),
            '{}',
            '{}',
            '{}',
            '{}'
        );
        System.assert(!book.success);

        Id rtId = Schema.SObjectType.Shipment__c.getRecordTypeInfosByDeveloperName().get('freightview').getRecordTypeId();
        Shipment__c ship = new Shipment__c(
            RecordTypeId = rtId,
            Name = 'FV Shipment',
            Active__c = true,
            shipmentID__c = 'SHIP123'
        );
        insert ship;

        shipmentRP.BookingResult docs = shipmentRP.saveFreightviewDocs(
            book.responseRaw,
            ship.Id,
            'u',
            'p',
            'https://mock.com'
        );
        Test.stopTest();

        System.assert(!docs.success);
    }

    @IsTest
    static void test_getLogisticLineItems() {
        Logistic__c lg = seed();
        Logistic_Line_Item__c li = new Logistic_Line_Item__c(
            Logistic__c = lg.Id,
            Quantity__c = 3
        );
        insert li;

        List<Logistic_Line_Item__c> result = shipmentRP.getLogisticLineItems(lg.Id);
        System.assertEquals(1, result.size());
        System.assertEquals(3, result[0].Quantity__c);
    }

    @IsTest
    static void test_getPackageDetails() {
        Package_Details__c p = new Package_Details__c(
            Name = 'Box Pkg',
            Package_Type__c = 'Box',
            Width__c = 10,
            Height__c = 12,
            Length__c = 15,
            Weight__c = 25,
            Weight_Unit__c = 'lbs'
        );
        insert p;

        Package_Details__c res = shipmentRP.getPackageDetails('Box');
        System.assertEquals('Box', res.Package_Type__c);
    }

    @IsTest
    static void test_getLogisticDetails() {
        Logistic__c lg = seed();
        shipmentRP.LogisticDetailsWrapper w = shipmentRP.getLogisticDetails(lg.Id);

        System.assertEquals(lg.Id, w.logistic.Id);
        System.assertNotEquals(null, w.fromAddress);
        System.assertNotEquals(null, w.toAddress);
        System.assertNotEquals(null, w.account);
        System.assertNotEquals(null, w.contact);
    }

    @IsTest
    static void test_getQuoteRatesLTL() {
        Credentials__c cred = new Credentials__c(
            Name = System.Label.AxoltFreightViewERP,
            URL__c = 'https://mock.com',
            Username_Login__c = 'u',
            Password_Transkey__c = 'p'
        );
        insert cred;

        Logistic__c lg = seed();

        List<String> providers = new List<String>{ 'freightview' };
        List<shipmentRP.PackageInputWrapper> pkg = new List<shipmentRP.PackageInputWrapper>();
        shipmentRP.PackageInputWrapper pi = new shipmentRP.PackageInputWrapper();
        pi.FVPackageType = 'Box';
        pkg.add(pi);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FV_Mock());
        shipmentRP.RateResponseLTL resp = shipmentRP.getQuoteRatesLTL(
            providers,
            JSON.serialize(lg.From_Address__r),
            JSON.serialize(lg.To_Address__r),
            JSON.serialize(lg),
            JSON.serialize(pkg),
            true,
            '2025-12-01',
            JSON.serialize(new Contact(LastName = 'A')),
            JSON.serialize(new Contact(LastName = 'B'))
        );
        Test.stopTest();
    }

    @IsTest
    static void test_bookSelectedQuote_FedEx_NotImplemented() {
        shipmentRP.BookingResult br = shipmentRP.bookSelectedQuote(
            'fedex',
            'Q123',
            'SHIP123',
            true,
            'ltl',
            '{}',
            '{}',
            '{}',
            '{}',
            '{}'
        );
        System.assert(!br.success);
        System.assert(br.message.contains('FedEx booking not implemented yet.'));
    }

    @IsTest
    static void test_bookSelectedQuote_UPS_NotImplemented() {
        shipmentRP.BookingResult br = shipmentRP.bookSelectedQuote(
            'ups',
            'Q123',
            'SHIP123',
            true,
            'ltl',
            '{}',
            '{}',
            '{}',
            '{}',
            '{}'
        );
        System.assert(!br.success);
        System.assert(br.message.contains('UPS booking not implemented yet.'));
    }

    @IsTest
    static void test_bookSelectedQuote_UnsupportedProvider() {
        shipmentRP.BookingResult br = shipmentRP.bookSelectedQuote(
            'dhl',
            'Q123',
            'SHIP123',
            true,
            'ltl',
            '{}',
            '{}',
            '{}',
            '{}',
            '{}'
        );
        System.assert(!br.success);
        System.assert(br.message.contains('Unsupported provider: dhl'));
    }

    @IsTest
    static void test_Full_Error_Paths_All_Catch() {
        Credentials__c cred = new Credentials__c(
            Name = System.Label.AxoltFreightViewERP,
            URL__c = 'https://mock.com',
            Username_Login__c = 'u',
            Password_Transkey__c = 'p'
        );
        insert cred;

        shipmentRP.BookingResult miss1 = shipmentRP.bookSelectedQuote(
            '',
            'Q1',
            'SH1',
            true,
            'ltl',
            '{}',
            '{}',
            '{}',
            '{}',
            '{}'
        );
        System.assert(!miss1.success);

        shipmentRP.BookingResult miss2 = shipmentRP.bookSelectedQuote(
            'freightview',
            '',
            'SH1',
            true,
            'ltl',
            '{}',
            '{}',
            '{}',
            '{}',
            '{}'
        );
        System.assert(!miss2.success);

        delete cred;
        shipmentRP.BookingResult credFail = shipmentRP.bookSelectedQuote(
            'freightview',
            'Q1',
            'SH1',
            true,
            'ltl',
            '{}',
            '{}',
            '{}',
            '{}',
            '{}'
        );
        System.assert(!credFail.success);

        shipmentRP.RateResponseLTL rateFail = shipmentRP.getQuoteRatesLTL(
            new List<String>{ 'freightview' },
            'NOT_JSON',
            'BAD_JSON',
            '{}',
            '[]',
            true,
            '2025-12-01',
            '{}',
            '{}'
        );

        cred = new Credentials__c(
            Name = System.Label.AxoltFreightViewERP,
            URL__c = 'https://mock.com',
            Username_Login__c = 'u',
            Password_Transkey__c = 'p'
        );
        insert cred;

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new BookingErrorMock());
        shipmentRP.BookingResult bookError = shipmentRP.bookSelectedQuote(
            'freightview',
            'Q123',
            'SHIP123',
            true,
            'ltl',
            '{}',
            '{}',
            '{}',
            '{}',
            '{}'
        );
        System.assert(!bookError.success);

        Test.setMock(HttpCalloutMock.class, new BlobNullMock());
        Id rtId = Schema.SObjectType.Shipment__c.getRecordTypeInfosByDeveloperName().get('freightview').getRecordTypeId();
        Shipment__c sh = new Shipment__c(
            RecordTypeId = rtId,
            Name = 'DocTest',
            Active__c = true,
            shipmentID__c = 'S1'
        );
        insert sh;

        String respRaw = '{"shipmentId":"S1","documents":[{"fileName":"BOL.pdf","downloadUrl":"https://mock.com/bol"}]}';
        shipmentRP.BookingResult docRes = shipmentRP.saveFreightviewDocs(
            respRaw,
            sh.Id,
            'u',
            'p',
            'https://mock.com'
        );

        Test.stopTest();

        System.assert(!docRes.success);
    }
}