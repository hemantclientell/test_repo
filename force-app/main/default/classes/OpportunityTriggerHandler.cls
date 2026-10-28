/**
 * Handler for OpportunityTrigger. Works out which Accounts are affected by the change
 * and hands them to OpportunityAmountRollupService in one bulk call.
 */
public with sharing class OpportunityTriggerHandler {

    // Lets data loads or tests switch the trigger off: OpportunityTriggerHandler.bypass = true;
    public static Boolean bypass = false;

    public void run() {
        if (bypass || !Trigger.isExecuting) {
            return;
        }

        Set<Id> accountIds = new Set<Id>();
        switch on Trigger.operationType {
            when AFTER_INSERT, AFTER_UNDELETE {
                accountIds = collectAccountIds((List<Opportunity>) Trigger.new);
            }
            when AFTER_DELETE {
                accountIds = collectAccountIds((List<Opportunity>) Trigger.old);
            }
            when AFTER_UPDATE {
                accountIds = collectChangedAccountIds(
                    (List<Opportunity>) Trigger.new,
                    (Map<Id, Opportunity>) Trigger.oldMap
                );
            }
        }

        if (!accountIds.isEmpty()) {
            OpportunityAmountRollupService.recalculate(accountIds);
        }
    }

    private static Set<Id> collectAccountIds(List<Opportunity> opportunities) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        return accountIds;
    }

    // Only Opportunities whose Amount or Account changed; a reparent affects both the old and new Account.
    private static Set<Id> collectChangedAccountIds(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.Amount == oldOpp.Amount && opp.AccountId == oldOpp.AccountId) {
                continue;
            }
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
            if (oldOpp.AccountId != null) {
                accountIds.add(oldOpp.AccountId);
            }
        }
        return accountIds;
    }
}
