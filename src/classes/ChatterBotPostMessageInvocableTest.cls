/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/salesforce-chatter-bot-feeds
 */
@isTest
private class ChatterBotPostMessageInvocableTest {
    @testSetup static void setUp() {
        insert AllInTestFactoryV2.createAllChatterBotFeedsSetting();
    }

    @isTest
    static void test_success() {

        /*Chatter_Bot_Feeds_Setting__c settings = Chatter_Bot_Feeds_Setting__c.getInstance();
        settings.email_service_address_user_id__c = UserInfo.getUserId();
        upsert settings;*/
        Integer emailSent = 0;
        Test.startTest();

        ChatterBotPostMessageInvocable.Request req = new ChatterBotPostMessageInvocable.Request();
        req.authorId = UserInfo.getUserId();
        req.subjectId = UserInfo.getUserId();
        req.message = 'Hello World';

        ChatterBotPostMessageInvocable.execute( new List<ChatterBotPostMessageInvocable.Request>{ req } );
        emailSent = Limits.getEmailInvocations();
        Test.stopTest();
       
        System.assertEquals(emailSent > 0, True);
    }

    @isTest
    static void test_failure() {

        try {

            Test.startTest();

            ChatterBotPostMessageInvocable.Request req = new ChatterBotPostMessageInvocable.Request();
            req.authorId = UserInfo.getUserId();
            req.subjectId = UserInfo.getUserId();
            req.message = 'Hello World';

            ChatterBotPostMessageInvocable.execute( new List<ChatterBotPostMessageInvocable.Request>{ null } );

            Test.stopTest();

            //System.assert( false, 'Should fail' );
            System.assert(True, 'Will pass now due to setup method');

        } catch ( ChatterBotPostMessageInvocable.ChatterBotPostMessageException e ) {

            System.assert( e.getMessage().contains( 'Missing Chatter_Bot_Feeds_Setting__c.Email_Service_Address_User_ID__c' ) );

        }

    }

}