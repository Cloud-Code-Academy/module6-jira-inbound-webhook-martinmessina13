public with sharing class CustomLogger {
    /**
     * Helper method to generate custom logs
     * @param exception The exception detail
     * @param logLevel The defined log level
     * @return void
     */
    public static void insertLog(Exception e, String logLevel){
        Custom_Log__c log = new Custom_Log__c();
        log.Message__c = e.getMessage();
        log.Log_Level__c = logLevel;
        log.Stack_Trace__c = e.getStackTraceString();
        if (Schema.SObjectType.Custom_Log__c.isCreateable()) {
            insert as user log;
        }
    }

    /**
     * Method overloading to cover informational activity messages
     * @param message The activity message detail
     * @param logLevel The defined log level
     * @return void
     */
    public static void insertLog(String message, String logLevel){
        Custom_Log__c log = new Custom_Log__c();
        log.Message__c = message;
        log.Log_Level__c = logLevel;
        if (Schema.SObjectType.Custom_Log__c.isCreateable()) {
            insert as user log;
        }
    }
}