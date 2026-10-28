@IsTest
private class ContactTriggerHandlerTest {

    @TestSetup
    static void setup() {
        insert new List<Account>{
            new Account(Name = 'Phone Account', Phone = '555-0100'),
            new Account(Name = 'No Phone Account')
        };
    }

    @IsTest
    static void insertWithoutPhoneCopiesAccountPhone() {
        Account acc = getAccount('Phone Account');

        Test.startTest();
        Contact con = new Contact(LastName = 'Copy', AccountId = acc.Id);
        insert con;
        Test.stopTest();

        Assert.areEqual('555-0100', getPhone(con.Id), 'Blank Phone should be copied from the Account');
    }

    @IsTest
    static void insertWithPhoneKeepsOwnPhone() {
        Account acc = getAccount('Phone Account');

        Test.startTest();
        Contact con = new Contact(LastName = 'Keep', AccountId = acc.Id, Phone = '555-0199');
        insert con;
        Test.stopTest();

        Assert.areEqual('555-0199', getPhone(con.Id), 'An existing Contact Phone should not be overwritten');
    }

    @IsTest
    static void updateClearingPhoneCopiesAccountPhone() {
        Account acc = getAccount('Phone Account');
        Contact con = new Contact(LastName = 'Clear', AccountId = acc.Id, Phone = '555-0199');
        insert con;

        Test.startTest();
        con.Phone = null;
        update con;
        Test.stopTest();

        Assert.areEqual('555-0100', getPhone(con.Id), 'Clearing Phone should fall back to the Account Phone');
    }

    @IsTest
    static void contactWithoutAccountIsUnchanged() {
        Test.startTest();
        Contact con = new Contact(LastName = 'Orphan');
        insert con;
        Test.stopTest();

        Assert.isNull(getPhone(con.Id), 'A Contact without an Account should keep a blank Phone');
    }

    @IsTest
    static void bulkInsertAcrossAccounts() {
        Account withPhone = getAccount('Phone Account');
        Account withoutPhone = getAccount('No Phone Account');
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(
                LastName = 'Bulk ' + i,
                AccountId = Math.mod(i, 2) == 0 ? withPhone.Id : withoutPhone.Id
            ));
        }

        Test.startTest();
        insert contacts;
        Test.stopTest();

        Assert.areEqual(100, [SELECT COUNT() FROM Contact WHERE Phone = '555-0100'], 'Contacts on the Account with a Phone get it');
        Assert.areEqual(100, [SELECT COUNT() FROM Contact WHERE AccountId = :withoutPhone.Id AND Phone = null], 'Contacts on the Account without a Phone stay blank');
    }

    @IsTest
    static void bypassSkipsHandler() {
        Account acc = getAccount('Phone Account');

        Test.startTest();
        ContactTriggerHandler.bypass = true;
        Contact con = new Contact(LastName = 'Bypass', AccountId = acc.Id);
        insert con;
        Test.stopTest();

        Assert.isNull(getPhone(con.Id), 'Handler should not run while bypassed');
    }

    private static Account getAccount(String name) {
        return [SELECT Id FROM Account WHERE Name = :name LIMIT 1];
    }

    private static String getPhone(Id contactId) {
        return [SELECT Phone FROM Contact WHERE Id = :contactId].Phone;
    }
}
