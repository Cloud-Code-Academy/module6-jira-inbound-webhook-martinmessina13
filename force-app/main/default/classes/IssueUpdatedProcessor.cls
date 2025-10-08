public without sharing class IssueUpdatedProcessor implements WebhookEventProcessor, Queueable {

    private Map<String, Object> payload;

    public IssueUpdatedProcessor(Map<String, Object> payload){
        this.payload = payload;
    }

    /**
     * @description Process an issue_updated event
     * @param payload The webhook payload
     */
    public void process(Map<String, Object> payload){
        try {
            Map<String, Object> issueData = (Map<String, Object>)payload.get('issue');
            String issueKey = (String) issueData.get('key');

            Jira_Issue__c queriedIssue = [
                SELECT 
                Issue_Key__c,
                Summary__c,
                Description__c,
                Project_Key__c
                FROM Jira_Issue__c
                WHERE Issue_Key__c = :issueKey
                
            ];
            
            Jira_Issue__c issue = JiraHelper.updateIssueRecord(queriedIssue, issueData);
            
            update issue;
            CustomLogger.insertLog('Updated Jira issue record: ' + issue.Id, LoggingLevel.DEBUG);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing issue_updated event: ' + e.getMessage());
            CustomLogger.insertLog(e, LoggingLevel.ERROR);
            throw e;
        }
    }

    public void execute(System.QueueableContext context){
        process(payload);
    }
}