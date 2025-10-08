public without sharing class IssueDeletedProcessor implements WebhookEventProcessor, Queueable{

    private Map<String, Object> payload;

    public IssueDeletedProcessor(Map<String, Object> payload){
        this.payload = payload;
    }

    /**
     * @description Process an issue_deleted event
     * @param payload The webhook payload
     */
    public void process(Map<String, Object> payload){
        try{
            Map<String,Object> issueData = (Map<String, Object>)payload.get('issue');
            String issueKey = (String)issueData.get('key');

            Jira_Issue__c issue = [
                SELECT Id 
                FROM Jira_Issue__c 
                WHERE Issue_Key__c = :issueKey 
                
            ];

            delete issue;
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Error processing issue_deleted event: ' + e.getMessage());
            CustomLogger.insertLog(e, LoggingLevel.ERROR);
            throw e;
        }
    }

    public void execute(System.QueueableContext context){
        process(payload);
    }
}