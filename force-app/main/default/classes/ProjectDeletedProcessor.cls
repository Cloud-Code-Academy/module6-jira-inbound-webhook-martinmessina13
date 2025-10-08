public without sharing class ProjectDeletedProcessor implements WebhookEventProcessor, Queueable {

    private Map<String, Object> payload;

    public ProjectDeletedProcessor(Map<String, Object> payload){
        this.payload = payload;
    }

    /**
     * @description Process an project_deleted event
     * @param payload The webhook payload
     */
    public void process(Map<String, Object> payload){
        try{
            Map<String, Object> projectData = (Map<String, Object>)payload?.get('project');
            String projectKey = (String)projectData?.get('key');

            Jira_Project__c queriedProject = [
                SELECT 
                Id
                FROM Jira_Project__c
                WHERE Project_Key__c = :projectKey
                
            ];

            delete queriedProject;
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Error processing project_deleted event: ' + e.getMessage());
            CustomLogger.insertLog(e, LoggingLevel.ERROR);
            throw e;
        }
    }

    public void execute(System.QueueableContext context){
        process(payload);
    }
}