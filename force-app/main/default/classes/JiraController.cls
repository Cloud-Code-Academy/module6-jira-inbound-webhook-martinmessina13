public with sharing class JiraController {
	@AuraEnabled(cacheable=true)
	public static List<Jira_Project__c> getProjects() {
		return [
			SELECT Id, Project_Name__c, Project_Key__c, Description__c
			FROM Jira_Project__c
			
		];
	}

	@AuraEnabled(cacheable=true)
	public static List<Jira_Issue__c> getIssues() {
		return [
			SELECT Id, Project_Key__c, Summary__c, Description__c, Issue_Type__c
			FROM Jira_Issue__c
			
		];
	}
}