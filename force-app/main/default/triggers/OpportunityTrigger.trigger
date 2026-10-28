/**
 * Single Opportunity trigger. Contains no logic; all work is delegated to OpportunityTriggerHandler.
 */
trigger OpportunityTrigger on Opportunity (after insert, after update, after delete, after undelete) {
    new OpportunityTriggerHandler().run();
}
