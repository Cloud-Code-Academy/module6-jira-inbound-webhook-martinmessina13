/** 
 * @description Interface for webhook event processors
 * @author Martin Messina 
 */
public interface WebhookEventProcessor {
    void process(Map<String, Object> payload);
}