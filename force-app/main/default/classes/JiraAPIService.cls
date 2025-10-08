/**
 * Service class for making callouts to the Jira API
 */
public with sharing class JiraAPIService {
	private static final String NAMED_CREDENTIAL = 'callout:JiraAPI'; //https://martinmessina13.atlassian.net/rest/api/3/
	private static final String PROJECT_ENDPOINT = '/project';
	private static final String ISSUE_ENDPOINT = '/issue';

	/**
	 * Creates a project in Jira
	 * @param projectWrapper The project wrapper object containing all necessary data
	 * @return String The Jira project ID
	 *
	 */
	public static String createProject(JiraWrapper.ProjectWrapper projectWrapper) {
		String endpoint = NAMED_CREDENTIAL + PROJECT_ENDPOINT;
		String body = JSON.serialize(projectWrapper);
		HttpResponse response = makeCallout(endpoint, body, 'POST');
		if (response.getStatusCode() == 201) {
			JiraWrapper.ResponseWrapper responseWrapper = parseResponse(response.getBody());
			return responseWrapper.id; // Return project ID
		} else if (response.getStatusCode() == 400) {
			return null;
		}
		throw new JiraException(response.getStatus());
	}

	/**
	 * Updates a project in Jira
	 * @param projectWrapper The project wrapper object containing all necessary data
	 * @return String The updated Jira project ID
	 * @return void
	 *
	 */
	public static String updateProject(
		JiraWrapper.ProjectWrapper projectWrapper,
		String projectId
	) {
		String endpoint = NAMED_CREDENTIAL + PROJECT_ENDPOINT + '/' + projectId;
		String body = JSON.serialize(projectWrapper);
		HttpResponse response = makeCallout(endpoint, body, 'PUT');
		if (response.getStatusCode() == 200) {
			JiraWrapper.ResponseWrapper responseWrapper = parseResponse(response.getBody());
			return responseWrapper.id; // Return project ID
		} else if (response.getStatusCode() == 400) {
			//CustomLogger.insertLog(formatErrors(response), 'ERROR');
			return null;
		}
		throw new JiraException(response.getStatus());
	}

	/**
	 * Creates an issue in Jira
	 * @param issueWrapper The issue wrapper object containing all necessary data
	 * @return String The Jira issue key
	 *
	 */
	public static String createIssue(JiraWrapper.IssueWrapper issueWrapper) {
		// Your implementation goes here
		String endpoint = NAMED_CREDENTIAL + ISSUE_ENDPOINT;
		String body = JSON.serialize(issueWrapper);
		HttpResponse response = makeCallout(endpoint, body, 'POST');
		if (response.getStatusCode() == 201) {
			JiraWrapper.ResponseWrapper responseWrapper = parseResponse(response.getBody());
			return responseWrapper.key; // Return issue key
		} else if (response.getStatusCode() == 400) {
			return null;
		}
		throw new JiraException(formatErrors(response));
	}

	/**
	 * Creates an issue in Jira
	 * @param issueWrapper The issue wrapper object containing all necessary data
	 * @param The Jira issue key
	 * @return String The updated Jira issue key
	 *
	 */
	public static String updateIssue(JiraWrapper.IssueWrapper issueWrapper, String issueKey) {
		// Your implementation goes here
		String endpoint = NAMED_CREDENTIAL + ISSUE_ENDPOINT + '/' + issueKey;
		String body = JSON.serialize(issueWrapper);
		HttpResponse response = makeCallout(endpoint, body, 'PUT');
		if (response.getStatusCode() == 204) {
			return response.getBody(); // Return body response
		} else if (response.getStatusCode() == 400) {
			return null;
		}
		throw new JiraException(formatErrors(response));
	}

	/**
	 * Helper method to make the HTTP POST callout
	 * @param endpoint The full URL with parameters
	 * @return HttpResponse The HTTP response
	 */
	private static HttpResponse makeCallout(String endpoint, String body, String method) {
		// - Create and configure HTTP request
		HttpRequest request = new HttpRequest();
		request.setEndpoint(endpoint);
		request.setMethod(method);
		request.setHeader('Content-Type', 'application/json');
		request.setBody(body);
		// - Make the callout
		Http http = new Http();
		HttpResponse response = http.send(request);
		return response;
	}

	/**
	 * Helper method to parse the JSON response
	 * @param jsonResponse The JSON response string
	 * @return JiraWrapper.ResponseWrapper The parsed response object
	 */
	private static JiraWrapper.ResponseWrapper parseResponse(String jsonResponse) {
		// - Deserialize JSON to JiraWrapper.ResponseWrapper
		try {
			return (JiraWrapper.ResponseWrapper) JSON.deserialize(
				jsonResponse,
				JiraWrapper.ResponseWrapper.class
			);
		} catch (Exception e) {
			// - Handle exceptions
			CustomLogger.insertLog(e, 'ERROR');
			throw new JiraException(e);
		}
	}

	/**
	 * Helper method to format errors coming in the endpoints response
	 * @param HttpResponse The HTTP response
	 * @return String String formatted errors
	 */
	private static String formatErrors(HttpResponse response) {
		JiraWrapper.ErrorWrapper error = (JiraWrapper.ErrorWrapper) JSON.deserialize(
			response.getBody(),
			JiraWrapper.ErrorWrapper.class
		);
		String errorMessage = response.getStatus() + '. ';
		if (!error.errorMessages.isEmpty()) {
			errorMessage += 'Error Messages: ' + error.errorMessages.toString() + '. ';
		}
		if (error.errors.size() > 0) {
			errorMessage += 'Errors detail: ' + error.errors + '. ';
		}
		return errorMessage;
	}

	public class JiraException extends Exception {
	}
}