/**
 * Developed by Doug Ayers (douglascayers.com)
 *
 * Apex plugin for the Change Opportunity Price Book flow to bulkify
 * the line item lookups and DML operations. In regular flow, this requires
 * lookups within a loop and we quickly exceed the governor SOQL limit.
 *
 * https://www.salesforce.com/us/developer/docs/apexcode/Content/apex_process_plugin.htm
 * https://www.salesforce.com/us/developer/docs/apexcode/Content/apex_process_plugin_example_lead_convert.htm
 */
global without sharing class ChangeOpportunityPriceBookPlugin implements Process.Plugin {

    // This method runs when called by a flow's Apex plug-in element.
    global Process.PluginResult invoke( Process.PluginRequest request ) {

        Map<String, Object> result = new Map<String, Object>();

        /* Input Parameters
        ---------------------------------------------------------------------*/

        String opportunityId = (String) request.inputParameters.get( 'opportunityId' );
        String priceBookId = (String) request.inputParameters.get( 'priceBookId' );
        Boolean overwriteUnitPrice = (Boolean) request.inputParameters.get( 'overwriteUnitPrice' );
        Boolean stopIfWillLoseLineItems = (Boolean) request.inputParameters.get( 'stopIfWillLoseLineItems' );

        System.debug( 'opportunityId=' + opportunityId );
        System.debug( 'priceBookId=' + priceBookId );
        System.debug( 'overwriteUnitPrice=' + overwriteUnitPrice );
        System.debug( 'stopIfWillLoseLineItems=' + stopIfWillLoseLineItems );

        /* Variables
        ---------------------------------------------------------------------*/

        // original list of line items on opportunity
        // will try to build up equivalent list based on same products in new price book
        List<OpportunityLineItem> oldLineItems = new List<OpportunityLineItem>([
            SELECT
                id, product2Id, product2.name, quantity, unitPrice, description
            FROM
                OpportunityLineItem
            WHERE
                opportunityId = :opportunityId
        ]);

        // will be the new list of line items to save on opportunity referencing new price book entries
        List<OpportunityLineItem> newLineItems = new List<OpportunityLineItem>();

        // these will be output parameters; below logic section computes their values
        Boolean newPriceBookIsMissingProducts = false; // indicates if new price book is missing any products used by original line items
        Set<String> missingProductNames = new Set<String>(); // product names missing from new price book used by original line items

        /* Logic
        ---------------------------------------------------------------------*/

        if ( oldLineItems.size() > 0 ) {

            System.debug( 'Opportunity has line items: ' + oldLineItems.size() );

            Set<String> oldProductNames = new Set<String>(); // line item product names in original price book
            Set<String> newProductNames = new Set<String>(); // matching line item products in new price book

            Set<ID> oldProductIds = new Set<ID>();
            Map<ID, OpportunityLineItem> oldLineItemsByProductIdMap = new Map<ID, OpportunityLineItem>();

            for ( OpportunityLineItem oldLineItem : oldLineItems ) {
                oldProductIds.add( oldLineItem.product2.id );
                oldProductNames.add( oldLineItem.product2.name );
                oldLineItemsByProductIdMap.put( oldLineItem.product2.id, oldLineItem );
            }

            System.debug( 'Getting equivalent price book entries from new price book for products on original line items' );
            System.debug( 'Original line item products: ' + oldProductNames );

            List<PriceBookEntry> newPriceBookEntries = new List<PriceBookEntry>([
                SELECT
                    id, product2Id, product2.name, unitPrice
                FROM
                    PriceBookEntry
                WHERE
                    isActive = true
                    AND
                    priceBook2Id = :priceBookId
                    AND
                    product2Id IN :oldProductIds
            ]);

            // build up a list of product names found in new price book entries
            // will use this to determine which products are missing from new price book (if any)
            for ( PriceBookEntry entry : newPriceBookEntries ) {

                newProductNames.add( entry.product2.name );

                OpportunityLineItem oldLineItem = oldLineItemsByProductIdMap.get( entry.product2.id );

                if ( oldLineItem != null ) {

                    OpportunityLineItem newLineItem = new OpportunityLineItem(
                        opportunityId = opportunityId,
                        priceBookEntryId = entry.id,
                        quantity = oldLineItem.quantity,
                        unitPrice = ( overwriteUnitPrice ? entry.unitPrice : oldLineItem.unitPrice ),
                        description = oldLineItem.description
                    );

                    System.debug( 'oldLineItem: ' + oldLineItem );
                    System.debug( 'newLineItem: ' + newLineItem );

                    newLineItems.add( newLineItem );

                }

            }

            // Check if new price book is missing any products on original line items
            newPriceBookIsMissingProducts = ( oldLineItems.size() != newPriceBookEntries.size() );

            // if missing any products then compute a new string set of the missing product names
            // we start with all the original product names then remove same product names from new price book
            // any product names remaining are ones that don't exist in the new price book
            if ( newPriceBookIsMissingProducts ) {
                missingProductNames = oldProductNames.clone();
                missingProductNames.removeAll( newProductNames );
            }

            System.debug( 'newPriceBookIsMissingProducts=' + newPriceBookIsMissingProducts );
            System.debug( 'missingProductNames=' + missingProductNames );

        } // end has old line items

        // Change opportunity to new price book?

        if ( newPriceBookIsMissingProducts && stopIfWillLoseLineItems ) {

            // do not update the opportunity, return back to flow so can prompt user how to proceed
            System.debug( 'Not changing opportunity! Flag set to not change opportunity price book because will lose line items' );

        } else {

            System.debug( 'Changing opportunity price book regardless if will lose some line items for products not in new price book' );

            if ( oldLineItems.size() > 0 ) {
                delete oldLineItems;
            }

            System.debug( 'Updating opportunity to new price book: opportunityId=' + opportunityId + ', priceBookId=' + priceBookId );

            Opportunity opp = [ SELECT id, priceBook2Id FROM Opportunity WHERE id = :opportunityId ];
            opp.priceBook2Id = priceBookId;
            update opp;

            System.debug( 'Inserting new line items: ' + newLineItems.size() );

            if ( newLineItems.size() > 0 ) {
                insert newLineItems;
            }

            System.debug( 'Opportunity price book changed and applicable new line items added!' );

        }

        /* Output Parameters
        ---------------------------------------------------------------------*/

        result.put( 'willLoseLineItems', newPriceBookIsMissingProducts );
        result.put( 'missingProductNames', String.join( new List<String>( missingProductNames ), ', ' ) );

        return new Process.PluginResult( result );
    }

    // This method describes the plug-in and its inputs from and outputs to the flow.
    // Implementing this method adds the class to the Cloud Flow Designer palette.
    global Process.PluginDescribeResult describe() {

        // Set up plugin metadata
        Process.PluginDescribeResult result = new Process.PluginDescribeResult();
        result.description = 'The ChangeOpportunityPriceBook Flow Plug-in changes the price book and keeps configured line items.';
        result.tag = 'Opportunity Management';

        // Create a list that stores both mandatory and optional input parameters from the flow.
        // NOTE: Only primitive types (STRING, NUMBER, etc.) are supported at this time.
        // Collections are currently not supported.
        result.inputParameters = new List<Process.PluginDescribeResult.InputParameter>{
            // Opportunity ID (required)
            new Process.PluginDescribeResult.InputParameter(
                'opportunityId',
                'The opportunity whose price book to change.',
                Process.PluginDescribeResult.ParameterType.STRING,
                true
            ),
            // Price Book ID (required)
            new Process.PluginDescribeResult.InputParameter(
                'priceBookId',
                'The new price book id to change the opportunity to.',
                Process.PluginDescribeResult.ParameterType.STRING,
                true
            ),
            // Overwrite unit price with new pricebook entry value? (required)
            new Process.PluginDescribeResult.InputParameter(
                'overwriteUnitPrice',
                'If true then sales prices will be updated to the prices in the new price book entries.',
                Process.PluginDescribeResult.ParameterType.BOOLEAN,
                true
            ),
            // Stop If Will Lose Line Items (required)
            new Process.PluginDescribeResult.InputParameter(
                'stopIfWillLoseLineItems',
                'If true then opportunity will not be updated if new price book does not contain the same products.',
                Process.PluginDescribeResult.ParameterType.BOOLEAN,
                true
            )
        };

        result.outputParameters = new List<Process.PluginDescribeResult.OutputParameter>{
            // Will Lose Line Items
            new Process.PluginDescribeResult.OutputParameter(
                'willLoseLineItems',
                'Indicates if the new price book does not contain the same products as the original price book and updating opportunity would yield fewer line items.',
                Process.PluginDescribeResult.ParameterType.BOOLEAN
            ),
            // Missing Product Names
            new Process.PluginDescribeResult.OutputParameter(
                'missingProductNames',
                'Comma-separated string of product names that do not exist in new price book that opportunity originally had line items for. Can use this to caution user.',
                Process.PluginDescribeResult.ParameterType.STRING
            )
        };

        return result;
    }

}
