import { LightningElement, wire } from "lwc";
import getProjects from "@salesforce/apex/JiraController.getProjects";
import getIssues from "@salesforce/apex/JiraController.getIssues";

const JP_COLUMNS = [
	{
		label: "Project Name",
		fieldName: "Project_Name__c",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "Project Key",
		fieldName: "Project_Key__c",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "Description",
		fieldName: "Description__c",
		type: "text",
		wrapText: true,
		hideDefaultActions: true
	}
];

const JI_COLUMNS = [
	{
		label: "Project Key",
		fieldName: "Project_Key__c",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "Summary",
		fieldName: "Summary__c",
		type: "text",
		wrapText: true,
		hideDefaultActions: true
	},
	{
		label: "Description",
		fieldName: "Description__c",
		type: "text",
		wrapText: true,
		hideDefaultActions: true
	},
	{
		label: "Issue Type",
		fieldName: "Issue_Type__c",
		type: "text",
		hideDefaultActions: true
	}
];

export default class JiraDisplay extends LightningElement {
	jpColumns = JP_COLUMNS;
	jiColumns = JI_COLUMNS;

	@wire(getProjects)
	projects;

	@wire(getIssues)
	issues;
}