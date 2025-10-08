public with sharing class JiraHelper {
    /**
     * @description Create a Jira_Issue__c record from issue data
     * @param issueData The issue data from the webhook
     * @return Jira_Issue__c The newly created issue record
     */
    public static Jira_Issue__c createIssueRecord(Map<String, Object> issueData) {
        Jira_Issue__c issue = mapIssueFields(new Jira_Issue__c(), issueData, true);
        return issue;
    }

    /**
     * @description Update a Jira_Issue__c record from issue data
     * @param existingIssue The existing issue record
     * @param issueData The updated issue data from the webhook
     * @return Jira_Issue__c The updated issue record
     */
    public static Jira_Issue__c updateIssueRecord(Jira_Issue__c existingIssue, Map<String, Object> issueData) {
        existingIssue = mapIssueFields(existingIssue, issueData, false);
        return existingIssue;
    }

    /**
     * @description Map issue fields from issue data to the Salesforce record
     * @param issue The issue record
     * @param issueData The updated issue data from the webhook
     * @param isCreate Flag to indicate creation or update
     * @return Jira_Issue__c The updated issue record
     */
    private static Jira_Issue__c mapIssueFields(Jira_Issue__c issue, Map<String, Object> issueData, Boolean isCreate){
        String issueKey = (String) issueData.get('key');
        Map<String, Object> fields = (Map<String, Object>)issueData.get('fields');
        Map<String, Object> status = (Map<String, Object>)fields?.get('status');
        Map<String, Object> issueType = (Map<String, Object>)fields?.get('issuetype');
        String issueTypeName = (String)issueType.get('name');
        Map<String, Object> project = (Map<String, Object>)fields?.get('project');
        String projectKey = (String)project.get('key');
        String summary = (String) fields?.get('summary');
        String description = (String) fields?.get('description');
        String statusName = (String)status.get('name');

        if(isCreate){
            issue = new Jira_Issue__c(
                Issue_Key__c = issueKey,
                Summary__c = summary,
                Description__c = description,
                Project_Key__c = projectKey,
                Issue_Type__c = issueTypeName,
                Status__c = statusName
            );
        }
        else{
            issue.Issue_Key__c = issueKey;
            issue.Summary__c = summary;
            issue.Description__c = description;
            issue.Project_Key__c = projectKey;
            issue.Issue_Type__c = issueTypeName;
            issue.Status__c = statusName;
        }

        return issue;
    }

    /**
     * @description Create a Jira_Project__c record from project data
     * @param projectData The project data from the webhook
     * @return Jira_Project__c The newly created project record
     */
    public static Jira_Project__c createProjectRecord(Map<String, Object> projectData) {
        Jira_Project__c project = mapProjectFields(new Jira_Project__c(), projectData, true);
        return project;
    }
    
    /**
     * @description Update a Jira_Project__c record from project data
     * @param existingProject The existing project record
     * @param projectData The updated project data from the webhook
     * @return Jira_Project__c The updated project record
     */
    public static Jira_Project__c updateProjectRecord(Jira_Project__c existingProject, Map<String, Object> projectData) {
        existingProject = mapProjectFields(existingProject, projectData, false);
        return existingProject;
    }

    private static Jira_Project__c mapProjectFields(Jira_Project__c project, Map<String, Object> projectData, Boolean isCreate){
        String projectName = (String)projectData.get('name');
        String projectKey = (String)projectData.get('key');
        String projectId = (String)String.valueOf((Integer)projectData.get('id'));
        String description = (String)projectData.get('description');
        
        if(isCreate){
            project = new Jira_Project__c(
                Project_Name__c = projectName,
                Project_Key__c = projectKey,
                Project_Id__c = projectId,
                Description__c = description
            );
        }
        else{
            project.Project_Name__c = projectName;
            project.Project_Key__c = projectKey;
            project.Project_Id__c = projectId;
            project.Description__c = description;
        }

        return project;
    }


}