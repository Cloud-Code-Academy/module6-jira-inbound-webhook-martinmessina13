/**
 * @description Processor for Jira webhooks
 * Handles issue and project events from Jira
 * @author Martin Messina
 */
public without sharing class JiraWebhookProcessor implements IWebhookProcessor {
    
    // Constants for webhook event types
    private static final String EVENT_ISSUE_CREATED = 'jira:issue_created';
    private static final String EVENT_ISSUE_UPDATED = 'jira:issue_updated';
    private static final String EVENT_ISSUE_DELETED = 'jira:issue_deleted';
    private static final String EVENT_PROJECT_CREATED = 'project_created';
    private static final String EVENT_PROJECT_UPDATED = 'project_updated';
    private static final String EVENT_PROJECT_DELETED = 'project_deleted';
    
    /**
     * @description Validates the incoming Jira webhook request
     * @param request The REST request containing the webhook payload
     * @return Boolean True if the request is valid, false otherwise
     */
    public Boolean validate(RestRequest request) {
        try {
            String requestBody = request.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            if (!payload.containsKey('webhookEvent')) {
                return false;
            }
            return true;
        } catch (Exception e) {
            // Log the error and return false
            System.debug(LoggingLevel.ERROR, 'Error validating webhook: ' + e.getMessage());
            CustomLogger.insertLog(e, LoggingLevel.ERROR);
            return false;
        }
    }
    
    /**
     * @description Processes the Jira webhook request
     * @param request The REST request containing the webhook payload
     */
    public void process(RestRequest request) {
        try {
            String requestBody = request.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            String webhookEvent = (String)payload.get('webhookEvent');

            WebhookEventProcessor processor;
            if(webhookEvent == EVENT_ISSUE_CREATED){
                processor = new IssueCreatedProcessor(payload);
            }
            else if(webhookEvent == EVENT_ISSUE_UPDATED){
                processor = new IssueUpdatedProcessor(payload);
            }
            else if(webhookEvent == EVENT_ISSUE_DELETED){
                processor = new IssueDeletedProcessor(payload);
            }
            else if(webhookEvent == EVENT_PROJECT_CREATED){
                processor = new ProjectCreatedProcessor(payload);
            }
            else if(webhookEvent == EVENT_PROJECT_UPDATED){
                processor = new ProjectUpdatedProcessor(payload);
            }
            else if(webhookEvent == EVENT_PROJECT_DELETED){
                processor = new ProjectDeletedProcessor(payload);
            }
            else{
                new UnsupportedEventException('Unsupported event type: ' + webhookEvent);
            }
            // Queue processor
            System.enqueueJob(processor);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing webhook: ' + e.getMessage());
            CustomLogger.insertLog(e, LoggingLevel.ERROR);
            throw e; // Re-throw to let the caller handle it
        }
    }

    public class UnsupportedEventException extends Exception {}
} 