public without sharing class ProjectCreatedProcessor implements WebhookEventProcessor, Queueable{

    private Map<String, Object> payload;

    public ProjectCreatedProcessor(Map<String, Object> payload){
        this.payload = payload;
    }

    /**
     * @description Process an project_created event
     * @param payload The webhook payload
     */
    public void process(Map<String, Object> payload){
        try{
            Map<String, Object> projectData = (Map<String, Object>)payload.get('project');
            Jira_Project__c project = JiraHelper.createProjectRecord(projectData);

            insert project;
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Error processing project_created event: ' + e.getMessage());
            CustomLogger.insertLog(e, LoggingLevel.ERROR);
            throw e;
        }
    }

    public void execute(System.QueueableContext context){
        process(payload);
    }
}