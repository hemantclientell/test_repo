/**
 * Single Contact trigger. Contains no logic; all work is delegated to ContactTriggerHandler.
 */
trigger ContactTrigger on Contact (before insert, before update) {
    new ContactTriggerHandler().run();
}
