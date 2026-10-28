@IsTest
private class OpportunityAmountRollupServiceTest {

    @TestSetup
    static void setup() {
        insert new List<Account>{
            new Account(Name = 'Rollup Account A'),
            new Account(Name = 'Rollup Account B')
        };
    }

    @IsTest
    static void insertSetsAccountTotal() {
        Account acc = getAccount('Rollup Account A');

        Test.startTest();
        insert new List<Opportunity>{ newOpp(acc.Id, 100), newOpp(acc.Id, 250.50) };
        Test.stopTest();

        Assert.areEqual(350.50, getAccount('Rollup Account A').Amount__c, 'Total should be the sum of both Opportunities');
    }

    @IsTest
    static void amountUpdateRecalculatesTotal() {
        Account acc = getAccount('Rollup Account A');
        Opportunity opp = newOpp(acc.Id, 100);
        insert new List<Opportunity>{ opp, newOpp(acc.Id, 50) };

        Test.startTest();
        opp.Amount = 400;
        update opp;
        Test.stopTest();

        Assert.areEqual(450, getAccount('Rollup Account A').Amount__c, 'Total should reflect the updated Amount');
    }

    @IsTest
    static void nullAmountIsTreatedAsZero() {
        Account acc = getAccount('Rollup Account A');
        Opportunity opp = newOpp(acc.Id, 100);
        insert opp;

        Test.startTest();
        opp.Amount = null;
        update opp;
        Test.stopTest();

        Assert.areEqual(0, getAccount('Rollup Account A').Amount__c, 'Total should be 0 when no Opportunity has an Amount');
    }

    @IsTest
    static void reparentUpdatesOldAndNewAccount() {
        Account accA = getAccount('Rollup Account A');
        Account accB = getAccount('Rollup Account B');
        Opportunity opp = newOpp(accA.Id, 300);
        insert opp;

        Test.startTest();
        opp.AccountId = accB.Id;
        update opp;
        Test.stopTest();

        Assert.areEqual(0, getAccount('Rollup Account A').Amount__c, 'Old Account should no longer include the Opportunity');
        Assert.areEqual(300, getAccount('Rollup Account B').Amount__c, 'New Account should include the Opportunity');
    }

    @IsTest
    static void deleteAndUndeleteRecalculateTotal() {
        Account acc = getAccount('Rollup Account A');
        Opportunity opp = newOpp(acc.Id, 200);
        insert new List<Opportunity>{ opp, newOpp(acc.Id, 50) };

        Test.startTest();
        delete opp;
        Assert.areEqual(50, getAccount('Rollup Account A').Amount__c, 'Deleted Opportunity should be removed from the total');
        undelete opp;
        Test.stopTest();

        Assert.areEqual(250, getAccount('Rollup Account A').Amount__c, 'Undeleted Opportunity should be added back to the total');
    }

    @IsTest
    static void bulkUpdateAcrossAccounts() {
        Account accA = getAccount('Rollup Account A');
        Account accB = getAccount('Rollup Account B');
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            opps.add(newOpp(Math.mod(i, 2) == 0 ? accA.Id : accB.Id, 10));
        }
        insert opps;

        Test.startTest();
        for (Opportunity opp : opps) {
            opp.Amount = 20;
        }
        update opps;
        Test.stopTest();

        Assert.areEqual(2000, getAccount('Rollup Account A').Amount__c, '100 Opportunities x 20');
        Assert.areEqual(2000, getAccount('Rollup Account B').Amount__c, '100 Opportunities x 20');
    }

    @IsTest
    static void bypassSkipsRollup() {
        Account acc = getAccount('Rollup Account A');

        Test.startTest();
        OpportunityTriggerHandler.bypass = true;
        insert newOpp(acc.Id, 100);
        Test.stopTest();

        Assert.isNull(getAccount('Rollup Account A').Amount__c, 'Rollup should not run while bypassed');
    }

    private static Opportunity newOpp(Id accountId, Decimal amount) {
        return new Opportunity(
            Name = 'Rollup Test Opp',
            AccountId = accountId,
            Amount = amount,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
    }

    private static Account getAccount(String name) {
        return [SELECT Id, Amount__c FROM Account WHERE Name = :name LIMIT 1];
    }
}
