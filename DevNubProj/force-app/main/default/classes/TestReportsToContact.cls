/*
---------------------------------------------------------------------------------------------------------------
* Test Class is to validate following automations : 
*  1 - Validation Rule in Contact Object:  DontAllowReportsToBlank.
*  2 - Flow : Update_Reports_To_Id
---------------------------------------------------------------------------------------------------------------
* @Author: Gabriela Teruel
*/
@isTest
public class TestReportsToContact {
    
    @TestSetup
    public static void createData() {
        
        // Create Default Contact to use on Account
        Contact contact = (Contact)TestDataFactory.createSObject('Contact', new Map<String, Object>{
                'LastName' => 'Test DefaultContact'
                }, true);
        
        // Create Account to use on positive and negative scenarios
        Account accWithCont = (Account)TestDataFactory.createSObject('Account', new Map<String, Object>{
                'Name' => 'Test Acc with DefaultContact',
                'DefaultContact__c' => contact.Id
                }, true);
        
        // Check if Account was created Correctly
        System.assertEquals(contact.Id, accWithCont.DefaultContact__c); 
    }
    
    @isTest
    public static void testBulkData() {
        
        // Get Parent Account with Default Contact
        Account acc = [SELECT Id, DefaultContact__c FROM Account WHERE DefaultContact__c != null LIMIT 1];
        
        Test.StartTest();
        // Creates 401 records for Bulk test
        List<Contact> createContacts = TestDataFactory.createSObjectList('Contact', new Map<String, Object>{
                'LastName'  => 'Test',
                'Birthdate' => Date.today(),
                'AccountId' => acc.Id
                }, 401, true);
        Test.StopTest();
        
        // Validate if all records ware updated with flow successfully and Bulk insert
        List<Contact> insertedContacts = [SELECT Id,ReportsToId FROM Contact WHERE ReportsToId != null];
        System.assertEquals(401, insertedContacts.size(), '401 Contacts were created with ReportsoId filled');      
        System.assertEquals(acc.DefaultContact__c, insertedContacts[0].ReportsToId,'The correct Contact was filled in the ReportsToField');  
    }
    
    @isTest
    public static void testPositiveScenarios() {
        // Get Parent Account with Default Contact
        Account acc = [SELECT Id, DefaultContact__c FROM Account LIMIT 1];
        
        Test.StartTest();
        // Creates Contact UNDER 18 to validate Flow and Validation Rule
        Contact contactUnder18 = (Contact)TestDataFactory.createSObject('Contact', new Map<String, Object>{
                'LastName'  => 'Test DefaultContact',
                'Birthdate' => Date.Today(),
                'AccountId' => acc.Id
                }, true);
        
        // Creates Contact OVER 18 to validate Flow and Validation Rule
        Contact contact = (Contact)TestDataFactory.createSObject('Contact', new Map<String, Object>{
                'LastName'  => 'Test DefaultContact Null',
                'Birthdate' => Date.Today().addYears(-20),
                'AccountId' => acc.Id
                }, true);
        Test.StopTest();
        
        //Validate Data
        List<Contact> contactsWithReportTo   = [SELECT Id,ReportsToId FROM Contact WHERE ReportsToId != null];
        List<Contact> contactsWithNOReportTo = [SELECT Id,ReportsToId FROM Contact WHERE ReportsToId=: null];
        System.assertEquals(1, contactsWithReportTo.size(), '1 Contact was created with ReportsToId filled'); 
        //2 contacts ware Created without ReportsToId, since @testSetup creates 1 also
        System.assertEquals(2,contactsWithNOReportTo.size(), '2 Contacts ware created with ReportsToId null');
        System.assertEquals(acc.DefaultContact__c, contactsWithReportTo[0].ReportsToId,'The correct Contact was filled in the ReportsToField');         
        
    }
    
    @isTest
    public static void testNegativeScenarios() {
        Exception expectedException;
        
        Test.startTest();
        //Try to create Contact UNDER 18 years with ReportsToId Blank       
        try{
            Contact contact = (Contact)TestDataFactory.createSObject('Contact', new Map<String, Object>{
                'LastName' => 'Test DefaultContact Null',
                'Birthdate' => Date.Today()
                }, true);
        }
        catch (Exception d){
            expectedException = d;
        }
        Test.stopTest();
        
        System.assertNotEquals(null, expectedException, 'The record should be validated and not saved');
    }
}