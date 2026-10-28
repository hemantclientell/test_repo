/**
 * Keeps Account.Amount__c equal to the sum of Amount across all of the Account's Opportunities.
 *
 * The query and update run in system mode on purpose: the total must include Opportunities
 * the current user cannot see, otherwise the stored value would depend on who made the edit.
 */
public with sharing class OpportunityAmountRollupService {

    public static void recalculate(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        Map<Id, Decimal> totalByAccount = new Map<Id, Decimal>();
        for (AggregateResult result : [
            SELECT AccountId accountId, SUM(Amount) total
            FROM Opportunity
            WHERE AccountId IN :accountIds
            WITH SYSTEM_MODE
            GROUP BY AccountId
        ]) {
            totalByAccount.put((Id) result.get('accountId'), (Decimal) result.get('total'));
        }

        // Only write Accounts whose stored total actually changes, to avoid needless DML and Account triggers.
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : [
            SELECT Id, Amount__c
            FROM Account
            WHERE Id IN :accountIds
            WITH SYSTEM_MODE
        ]) {
            Decimal total = totalByAccount.get(acc.Id);
            Decimal newAmount = total == null ? 0 : total;
            if (acc.Amount__c != newAmount) {
                accountsToUpdate.add(new Account(Id = acc.Id, Amount__c = newAmount));
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            Database.update(accountsToUpdate, true, AccessLevel.SYSTEM_MODE);
        }
    }
}
