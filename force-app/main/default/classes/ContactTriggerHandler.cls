/**
 * Dummy handler for ContactTrigger: when a Contact has no Phone, copy the Phone from its Account.
 */
public with sharing class ContactTriggerHandler {

    // Lets data loads or tests switch the trigger off: ContactTriggerHandler.bypass = true;
    public static Boolean bypass = false;

    public void run() {
        if (bypass || !Trigger.isExecuting) {
            return;
        }

        switch on Trigger.operationType {
            when BEFORE_INSERT, BEFORE_UPDATE {
                defaultPhoneFromAccount((List<Contact>) Trigger.new);
            }
        }
    }

    private static void defaultPhoneFromAccount(List<Contact> contacts) {
        Set<Id> accountIds = new Set<Id>();
        for (Contact con : contacts) {
            if (String.isBlank(con.Phone) && con.AccountId != null) {
                accountIds.add(con.AccountId);
            }
        }
        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Account> accountsById = new Map<Id, Account>([
            SELECT Id, Phone
            FROM Account
            WHERE Id IN :accountIds
            WITH USER_MODE
        ]);

        for (Contact con : contacts) {
            if (String.isBlank(con.Phone) && accountsById.containsKey(con.AccountId)) {
                con.Phone = accountsById.get(con.AccountId).Phone;
            }
        }
    }
}
