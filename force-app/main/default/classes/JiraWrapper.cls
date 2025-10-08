/**
 * Wrapper classes for Jira entities (Project and Issue)
 */
public class JiraWrapper {
	private static final String LEAD_ACCOUNT_ID = '70121:d6dfd1f0-16cd-4155-aed4-e1b4f6be5c35';
	private static final String PROJECT_TEMPLATE_KEY = 'com.pyxis.greenhopper.jira:basic-software-development-template';

	/**
	 * Wrapper for Jira Project
	 */
	public class ProjectWrapper {
		public String name;
		public String key;
		public String description;
		public String leadAccountId;
		public String projectTemplateKey;

		/**
		 * Constructor for ProjectWrapper
		 */
		public ProjectWrapper(String name, String key, String description) {
			this.name = name;
			this.key = key;
			this.description = description;
			this.leadAccountId = LEAD_ACCOUNT_ID;
			this.projectTemplateKey = PROJECT_TEMPLATE_KEY;
		}
	}

	/**
	 * Wrapper for Jira Issue
	 */
	public class IssueWrapper {
		public Fields fields;

		/**
		 * Constructor for IssueWrapper
		 */
		public IssueWrapper(
			String projectKey,
			String summary,
			String description,
			String issueType
		) {
			this.fields = generateIssuePayloadMap(projectKey, summary, description, issueType);
		}

		/**
		 * Convert IssueWrapper to a Fields object for serialization
		 */
		public Fields generateIssuePayloadMap(
			String projectKey,
			String summary,
			String description,
			String issueType
		) {
			Fields fieldsObject = new Fields();
			fieldsObject.project = formatProject(projectKey);
			fieldsObject.description = formatDescription(description);
			fieldsObject.summary = summary;
			fieldsObject.issuetype = formatIssueType(issueType);
			return fieldsObject;
		}

		/**
		 * Format description as per Jira Cloud API requirements
		 */
		private JiraWrapper.Description formatDescription(String description) {
			JiraWrapper.Description descriptionWrapper = new JiraWrapper.Description();
			descriptionWrapper.type = 'doc';
			descriptionWrapper.version = 1;

			JiraWrapper.EmbeddedContent embeddedContent = new JiraWrapper.EmbeddedContent();
			embeddedContent.type = 'text';
			embeddedContent.text = description;

			List<JiraWrapper.EmbeddedContent> embeddedContents = new List<JiraWrapper.EmbeddedContent>{
				embeddedContent
			};

			JiraWrapper.Content content = new JiraWrapper.Content();
			content.content = embeddedContents;
			content.type = 'paragraph';

			List<JiraWrapper.Content> contents = new List<JiraWrapper.Content>{ content };
			descriptionWrapper.content = contents;

			return descriptionWrapper;
		}

		/**
		 * Format issue type as per Jira Cloud API requirements
		 */
		private JiraWrapper.Issuetype formatIssueType(String issueType) {
			String issueTypeName = (String.isNotBlank(issueType)) ? issueType : 'Task';
			JiraWrapper.Issuetype issuetypeWrapper = new JiraWrapper.Issuetype();
			issuetypeWrapper.name = issueTypeName;
			return issuetypeWrapper;
		}

		/**
		 * Format project as per Jira Cloud API requirements
		 */
		private JiraWrapper.Project formatProject(String projectKey) {
			JiraWrapper.Project project = new JiraWrapper.Project();
			project.key = projectKey;
			return project;
		}
	}

	/**
	 * Wrapper for Jira Issue's fields
	 */
	class Fields {
		public Description description;
		public Project project;
		public String summary;
		public Issuetype issuetype;
	}

	class Project {
		public String key;
	}

	class Issuetype {
		public String name;
	}

	class Description {
		public Content[] content;
		public String type; //doc
		public Integer version; //1
	}

	class EmbeddedContent {
		public String text;
		public String type; //text
	}

	class Content {
		public EmbeddedContent[] content;
		public String type; //paragraph
	}

	/*
	 * Wrapper for Jira responses
	 */
	public class ResponseWrapper {
		public String id;
		public String key;
		public String self;
	}

	public class ErrorWrapper {
		public List<String> errorMessages;
		public Map<String, String> errors;
	}
}