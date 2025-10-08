public without sharing class IssueCreatedProcessor implements WebhookEventProcessor, Queueable {

    private Map<String, Object> payload;

    public IssueCreatedProcessor(Map<String, Object> payload){
        this.payload = payload;
    }

    /**
     * @description Process an issue_created event
     * @param payload The webhook payload
     */
    public void process(Map<String, Object> payload){
        try {
            Map<String, Object> issueData = (Map<String, Object>)payload.get('issue');
            
            Jira_Issue__c newIssue = JiraHelper.createIssueRecord(issueData);
            
            insert newIssue;
            CustomLogger.insertLog('Created Jira issue record: ' + newIssue.Id, LoggingLevel.DEBUG);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing issue_created event: ' + e.getMessage());
            CustomLogger.insertLog(e, LoggingLevel.ERROR);
            throw e;
        }
    }

    public void execute(System.QueueableContext context){
        process(payload);
    }
}