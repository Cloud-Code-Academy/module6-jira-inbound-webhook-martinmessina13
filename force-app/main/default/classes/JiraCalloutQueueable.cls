/**
 * Queueable class to make asynchronous callouts to Jira API
 */
public class JiraCalloutQueueable implements Queueable, Finalizer, Database.AllowsCallouts {
	// Simple constants instead of enum
	public static final String TYPE_PROJECT = 'PROJECT';
	public static final String TYPE_ISSUE = 'ISSUE';
	public static final Integer BATCH_SIZE = 20;
	private static final Integer MAX_RETRIES = 3;

	private String calloutType;
	private JiraWrapper.ProjectWrapper projectWrapper;
	private JiraWrapper.IssueWrapper issueWrapper;

	List<SObject> records;
	private Integer batchSize;
	private Integer currentIndex;
	private Integer endIndex;

	List<SObject> clones = new List<SObject>();

	// A list to hold records that fail in this specific job execution
	List<SObject> failedRecordsInThisJob = new List<SObject>();

	private Integer retryCount;

	public class JobParameters {
		public Integer batchSize;
		public Integer currentIndex;
		public Integer retryCount;
	}

	/**
	 * Constructor for Jira Project callout
	 * @param records The Salesforce records (Jira_Project__c/Jira_Issue__C)
	 * @param batchSize Batch size of the records
	 * @param currentIndex Current index of the sublist batch
	 * @param retryCount Failed jobs retry counter
	 */
	public JiraCalloutQueueable(List<SObject> records, String calloutType, JobParameters params) {
		this.records = records;
		this.calloutType = calloutType;
		this.batchSize = params.batchSize != null ? params.batchSize : BATCH_SIZE; //Default to BATCH_SIZE
		this.currentIndex = params.currentIndex;
		this.retryCount = params.retryCount != null ? params.retryCount : 0;
	}

	/**
	 * Execute the callout based on the callout type
	 */
	public void execute(QueueableContext context) {
		// Choose the min value between the length of the records list and the current index increased by batch size
		endIndex = Math.min(records.size(), currentIndex + batchSize);

		// Take BATCH_SIZE projects objects from list and form a sublist
		List<SObject> recordsSublist = getSublist(records, currentIndex, endIndex);

		// Create entities in Jira, callouts first
		Map<Id, String> successfulJiraIds = syncToJira(recordsSublist);

		// Setting Finalizer parameters
		JobParameters finalizerParams = new JobParameters();
		finalizerParams.batchSize = BATCH_SIZE;
		finalizerParams.currentIndex = this.currentIndex;
		finalizerParams.retryCount = this.retryCount;

		System.debug('failedRecords before finalizer: ' + this.failedRecordsInThisJob);

		// Attaching Finalizer
		System.attachFinalizer(
			new JiraCalloutQueueable(this.failedRecordsInThisJob, this.calloutType, finalizerParams)
		);

		try {
			if (!successfulJiraIds.isEmpty()) {
				// DML operations, after making the callouts
				insertSuccessfulLogs(successfulJiraIds.values());
				// Update Project Id or Issue Key in Salesforce records
				updateSalesforceRecords(successfulJiraIds);
			}

			if (endIndex < records.size()) {
				if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
					throw new JiraAPIService.JiraException(
						'Job ID: ' +
							context.getJobId() +
							'. Insufficient number of jobs left to proceed with callouts. Try increasing the batch size of the job.'
					);
				}
				JobParameters params = new JobParameters();
				params.batchSize = batchSize;
				params.retryCount = 0;
				params.currentIndex = endIndex;
				JiraCalloutQueueable queueable = new JiraCalloutQueueable(
					records,
					calloutType,
					params
				);
			}
		} catch (Exception e) {
			CustomLogger.insertLog(e, 'ERROR');
		}
	}

	/**
	 * Bulk-updates Salesforce records after successful callouts.
	 */
	private void updateSalesforceRecords(Map<Id, String> successfulJiraIds) {
		List<SObject> recordsToUpdate = new List<SObject>();
		if (calloutType == TYPE_PROJECT) {
			for (Id recordId : successfulJiraIds.keySet()) {
				recordsToUpdate.add(
					new Jira_Project__c(
						Id = recordId,
						Project_ID__c = successfulJiraIds.get(recordId)
					)
				);
			}
		} else {
			for (Id recordId : successfulJiraIds.keySet()) {
				recordsToUpdate.add(
					new Jira_Issue__c(
						Id = recordId,
						Issue_Key__c = successfulJiraIds.get(recordId),
						Last_Updated__c = System.now()
					)
				);
			}
		}

		if (!recordsToUpdate.isEmpty()) {
			update as user recordsToUpdate;
		}
	}

	/**
	 * Utility method to extract a subset of elements from a main list
	 */
	private List<SObject> getSublist(List<SObject> records, Integer firstIndex, Integer lastIndex) {
		List<SObject> sublist = new List<SObject>();
		if (firstIndex < 0 || lastIndex < 0 || lastIndex > records.size()) {
			throw new ListException('Index out of bounds.');
		}
		for (Integer i = firstIndex; i < lastIndex; i++) {
			sublist.add(records[i]);
		}
		return sublist;
	}

	/**
	 * Utility method to insert informational messages about synced projects/issues
	 * Logs are inserted after callout to avoid mixed callot exception
	 */
	private void insertSuccessfulLogs(List<String> successfulJiraIds) {
		for (String jiraId : successfulJiraIds) {
			CustomLogger.insertLog(
				calloutType == TYPE_PROJECT
					? 'Project with ID \'' + jiraId + '\' successfully created in Jira.'
					: 'Issue with with key \'' + jiraId + '\' successfully created in Jira.',
				'INFO'
			);
		}
	}

	/**
	 * Utility method that generates wrapper payloads and syncs records to Jira
	 */
	private Map<Id, String> syncToJira(List<SObject> records) {
		Map<Id, String> successfulJiraIds = new Map<Id, String>();

		for (SObject record : records) {
			try {
				String jiraId;
				if (calloutType == TYPE_PROJECT) {
					Jira_Project__c project = (Jira_Project__c) record;
					JiraWrapper.ProjectWrapper projectWrapper = new JiraWrapper.ProjectWrapper(
						project.Project_Name__c,
						project.Project_Key__c,
						project.Description__c
					);
					// Make callouts with projects sublist wrappers
					jiraId = JiraAPIService.createProject(projectWrapper);
				} else {
					Jira_Issue__c issue = (Jira_Issue__c) record;
					JiraWrapper.IssueWrapper issueWrapper = new JiraWrapper.IssueWrapper(
						issue.Project_Key__c,
						issue.Summary__c,
						issue.Description__c,
						issue.Issue_Type__c
					);
					// Make callouts with issue sublist wrappers
					jiraId = JiraAPIService.createIssue(issueWrapper);
				}
				if (jiraId != null) {
					successfulJiraIds.put(record.Id, jiraId);
				} else {
					throw new JiraAPIService.JiraException(
						'There has been an error syncing the record to Jira'
					);
				}
			} catch (JiraAPIService.JiraException e) {
				this.failedRecordsInThisJob.add(record);
				System.debug('failed records: ' + this.failedRecordsInThisJob);
			}
		}

		return successfulJiraIds;
	}

	/**
	 * Finalizer execute method
	 * Triggers retry mechanism after job succeeds or fails
	 */
	public void execute(FinalizerContext context) {
		System.debug('entering finalizer context');
		System.debug('this.records: ' + this.records);
		if (!this.records.isEmpty()) {
			if (this.retryCount < MAX_RETRIES) {
				CustomLogger.insertLog(
					'Job ' +
						context.getAsyncApexJobId() +
						' failed. Retrying ' +
						this.records.size() +
						' records. Attempt #' +
						(this.retryCount + 1) +
						'.',
					'WARN'
				);
				JobParameters params = new JobParameters();
				params.batchSize = BATCH_SIZE;
				params.currentIndex = this.currentIndex;
				params.retryCount = this.retryCount + 1;
				System.debug('queued retry # ' + this.retryCount + 1);

				System.enqueueJob(new JiraCalloutQueueable(this.records, this.calloutType, params));
			} else {
				CustomLogger.insertLog(
					'Job ' +
						context.getAsyncApexJobId() +
						' failed after ' +
						MAX_RETRIES +
						' retried. ' +
						this.records.size() +
						' records could not be synced.',
					'ERROR'
				);
			}
		}
	}
}