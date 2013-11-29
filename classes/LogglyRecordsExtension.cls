public with sharing class LogglyRecordsExtension {
	
	private Id orgId;

	public LogglyRecordsExtension(ApexPages.StandardController con) {
		
		List<Account> accs = [SELECT Id, Org_Id__c FROM Account WHERE Id = :con.getId()];
		if(!accs.isEmpty())
			orgId = accs[0].Org_Id__c;
	}

	public List<LogglyClientStep3.LogItem> getMostRecentLogs(){

		return LogglyClientStep3.retrieveLogItems('json.orgId:' + orgId, null, null, null, 10);

	}
}