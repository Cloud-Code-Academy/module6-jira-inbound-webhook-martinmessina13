public without sharing class ProjectUpdatedProcessor implements WebhookEventProcessor, Queueable {

    private Map<String, Object> payload;

    public ProjectUpdatedProcessor(Map<String, Object> payload){
        this.payload = payload;
    }

    /**
     * @description Process an project_updated event
     * @param payload The webhook payload
     */
    public void process(Map<String, Object> payload){
        try{
            Map<String, Object> projectData = (Map<String, Object>)payload.get('project');
            String projectKey = (String)projectData.get('key');

            Jira_Project__c queriedProject = [
                SELECT 
                Project_Name__c,
				Project_Key__c,
				Description__c
                FROM Jira_Project__c
                WHERE Project_Key__c = :projectKey
                
            ];

            Jira_Project__c project = JiraHelper.updateProjectRecord(queriedProject, projectData);

            update project;
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Error processing project_updated event: ' + e.getMessage());
            CustomLogger.insertLog(e, LoggingLevel.ERROR);
            throw e;
        }
    }

    public void execute(System.QueueableContext context){
        process(payload);
    }
}