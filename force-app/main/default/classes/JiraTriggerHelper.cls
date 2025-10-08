/**
 * Helper class for Jira triggers
 * Queue job passes list of projects/issues and batch size for chaining purposes
 * This is done to avoid hitting queueable and callouts limit related exceptions
 */
public with sharing class JiraTriggerHelper {
	/**
	 * Process Jira_Project__c records after insert
	 * @param newProjects List of newly inserted Jira_Project__c records
	 */
	public static void processProjectAfterInsert(List<Jira_Project__c> newProjects) {
		List<Jira_Project__c> projectsToProcess = new List<Jira_Project__c>();

		// Filter out projects that already have a Jira project ID
		for (Jira_Project__c project : newProjects) {
			if (String.isBlank(project.Project_ID__c)) {
				projectsToProcess.add(project);
			}
		}

		if (!projectsToProcess.isEmpty()) {
			enqueueJob(projectsToProcess, JiraCalloutQueueable.TYPE_PROJECT);
		} else {
			CustomLogger.insertLog('There are no projects to create in Jira.', 'INFO');
		}
	}

	/**
	 * Process Jira_Issue__c records after insert
	 * @param newIssues List of newly inserted Jira_Issue__c records
	 */
	public static void processIssueAfterInsert(List<Jira_Issue__c> newIssues) {
		List<Jira_Issue__c> issuesToProcess = new List<Jira_Issue__c>();
		for (Jira_Issue__c newIssue : newIssues) {
			if (String.isBlank(newIssue.Issue_Key__c)) {
				// Ensure project key field is populated
				if (String.isBlank(newIssue.Project_Key__c)) {
					String message =
						'Jira Issue with key \'' +
						newIssue.Issue_Key__c +
						'\' and summary \'' +
						newIssue.Summary__c +
						'\' does not have a project key and won\'t be synced in Jira.';
					CustomLogger.insertLog(message, 'ERROR');
					continue;
				}
				issuesToProcess.add(newIssue);
			}
		}

		if (!issuesToProcess.isEmpty()) {
			enqueueJob(issuesToProcess, JiraCalloutQueueable.TYPE_ISSUE);
		} else {
			CustomLogger.insertLog('There are no issues to create in Jira.', 'INFO');
		}
	}

	/**
	 * Utilitary method to enqueue Queueable job
	 * @param JiraCalloutQueuable Queueable job to queue
	 */
	private static void enqueueJob(List<SObject> records, String calloutType) {
		if (!Test.isRunningTest()) {
			try {
				// Queue job if within queueable governor limits
				if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
					JiraCalloutQueueable.JobParameters params = new JiraCalloutQueueable.JobParameters();

					params.batchSize = JiraCalloutQueueable.BATCH_SIZE;
					params.currentIndex = 0;
					params.retryCount = 0;

					System.enqueueJob(new JiraCalloutQueueable(records, calloutType, params));
					return;
				}
				throw new JiraAPIService.JiraException(
					'Queueable jobs limit has been reached, the callouts to the Jira API could not be queued.'
				);
			} catch (Exception e) {
				CustomLogger.insertLog(e, 'ERROR');
			}
		}
	}
}