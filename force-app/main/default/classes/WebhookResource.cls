/**
 * @description REST resource to handle incoming webhooks from various systems
 * Current implementation supports Jira webhooks at /webhook/jira
 * @author Martin Messina
 */
@RestResource(urlMapping='/webhook/*')
global without sharing class WebhookResource {
    
    /**
     * @description Handles POST requests from webhooks
     * @return Returns a simple success response
     */
    @HttpPost
    global static ResponseWrapper doPost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        try{
            String webhookType = getWebhookTypeFromPath(request.requestURI);
            WebhookFactory.processWebhook(webhookType, request);
            return new ResponseWrapper('success', 'Processed successfully');
        }
        catch(JSONException e){
            CustomLogger.insertLog(e, LoggingLevel.ERROR);
            return new ResponseWrapper('error', 'Malformed JSON object');
        }
        catch(Exception e){
            CustomLogger.insertLog(e, LoggingLevel.ERROR);
            return new ResponseWrapper('error', 'Unsupported webhook type');
        }

    }
    
    /**
     * @description Extracts the webhook type from the URL path
     * @param path The request URI
     * @return The webhook type (e.g., "jira")
     */
    private static String getWebhookTypeFromPath(String path) {
        System.debug('getWebhookTypeFromPath: ' + path);
        // Expected formats: /webhook/jira or /services/apexrest/webhook/jira
        if (path == null) {
            return '';
        }
        
        // Look for the webhook segment in the path
        Integer webhookIndex = path.indexOf('/webhook/');
        
        if (webhookIndex >= 0) {
            // Extract the part after /webhook/
            String remaining = path.substring(webhookIndex + 9);
            System.debug('remaining: ' + remaining);
            
            // If there are additional slashes, only take the first segment
            Integer nextSlash = remaining.indexOf('/');
            if (nextSlash > 0) {
                System.debug('nextSlash: ' + nextSlash);
                return remaining.substring(0, nextSlash).toLowerCase();
            }
            
            return remaining.toLowerCase();
        }
        
        return '';
    }
    
    /**
     * @description Response wrapper class for consistent response format
     */
    global class ResponseWrapper {
        public String status;
        public String message;
        
        public ResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message;
        }
    }
} 