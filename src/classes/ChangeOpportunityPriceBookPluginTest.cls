@isTest
private class ChangeOpportunityPriceBookPluginTest {

	@isTest
    static void test_change_pricebook() {

        Product2 prodA = new Product2( name = 'Test Product A' );
        insert prodA;

        Product2 prodB = new Product2( name = 'Test Product B' );
        insert prodB;

        PriceBook2 bookA = new PriceBook2( name = 'Test PriceBook A', isActive = true );
        insert bookA;

        PriceBookEntry pbeA1 = new PriceBookEntry(
            pricebook2Id = Test.getStandardPriceBookId(),
            product2Id = prodA.id,
            isActive = true,
            unitPrice = 100
        );
        insert pbeA1;

        PriceBookEntry pbeA2 = new PriceBookEntry(
            pricebook2Id = bookA.id,
            product2Id = prodA.id,
            isActive = true,
            unitPrice = 100
        );
        insert pbeA2;

        PriceBookEntry pbeB1 = new PriceBookEntry(
            pricebook2Id = Test.getStandardPriceBookId(),
            product2Id = prodB.id,
            isActive = true,
            unitPrice = 100
        );
        insert pbeB1;

        PriceBookEntry pbeB2 = new PriceBookEntry(
            pricebook2Id = bookA.id,
            product2Id = prodB.id,
            isActive = true,
            unitPrice = 100
        );
        insert pbeB2;

        Account acct = new Account(
            name = 'Test Account'
        );
        insert acct;

        Opportunity oppty = new Opportunity(
            name = 'Test Oppty',
            accountId = acct.id,
            stageName = 'Prospecting',
            closeDate = Date.today()
        );
        insert oppty;

        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                opportunityId = oppty.id,
                priceBookEntryId = pbeA1.id,
                unitPrice = 50,
                quantity = 10
            ),
            new OpportunityLineItem(
                opportunityId = oppty.id,
                priceBookEntryId = pbeB1.id,
                unitPrice = 50,
                quantity = 10
            )
        };
        insert lineItems;

        Test.startTest();

        ChangeOpportunityPriceBookPlugin plugin = new ChangeOpportunityPriceBookPlugin();

        plugin.describe();

        Process.PluginRequest request = new Process.PluginRequest( new Map<String, Object>{
            'opportunityId' => oppty.id,
            'priceBookId' => bookA.id,
            'stopIfWillLoseLineItems' => false
        });

        Process.PluginResult result = plugin.invoke( request );

        Test.stopTest();

        System.assertEquals( false, (Boolean) result.outputParameters.get( 'willLoseLineItems' ) );
        System.assertEquals( '', (String) result.outputParameters.get( 'missingProductNames' ) );

        List<OpportunityLineItem> newLineItems = new List<OpportunityLineItem>([
            SELECT
                id, priceBookEntryId, priceBookEntry.product2Id, unitPrice, quantity
            FROM
                OpportunityLineItem
            WHERE
                opportunityId = :oppty.id
        ]);

        System.assert( lineItems.size() == newLineItems.size() );

        Set<ID> oldProductIds = new Set<ID>{ prodA.id, prodB.id }; // can't use 'lineItems' because product2id isn't yet populated
        Set<ID> newProductIds = getProductIds( newLineItems ); // can use util method because we queried these from database

        System.debug( 'oldProductIds=' + oldProductIds );
        System.debug( 'newProductIds=' + newProductIds );

        System.assert( oldProductIds.containsAll( newProductIds ) );
        System.assert( newProductIds.containsAll( oldProductIds ) );

	}

    static Set<ID> getProductIds( List<OpportunityLineItem> lineItems ) {
        Set<ID> ids = new Set<ID>();
        for ( OpportunityLineItem lineItem : lineItems ) {
            ids.add( lineItem.priceBookEntry.product2Id );
        }
        return ids;
    }

}