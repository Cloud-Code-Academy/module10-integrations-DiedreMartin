
public with sharing class ContactDummyJsonHandler {
    public static void handleBeforeInsert(List<Contact> newContacts){
        for(Contact contact : newContacts) {
            if (contact.DummyJSON_Id__c == null) {
                contact.DummyJSON_Id__c = String.valueOf((Integer) Math.floor(Math.random() * 101));
            } 
        }
    }
        
    public static void handleAfterInsert(List<Contact> newContacts) {
        for (Contact contact : newContacts) {
            if (contact.DummyJSON_Last_Updated__c != null && contact.DummyJSON_Last_Updated__c.date() == Date.today()){
                continue;
            }
            if (!Test.isRunningTest()) {
                DummyJSONCallout.getDummyJSONUserFromIdFuture(contact.Id);
            }
        }
    }    

    public static void handleAfterUpdate(List<Contact> updatedContacts) {
        for (Contact contact : updatedContacts) {
            if (contact.DummyJSON_Id__c != null && Integer.valueOf(contact.DummyJSON_Id__c) > 100) {
                DummyJSONCallout.callPostCreateDummyJSONUserFuture(contact.Id);
            }
        }
    }
}
  


