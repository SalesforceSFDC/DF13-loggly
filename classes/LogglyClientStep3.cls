public with sharing class LogglyClientStep3 {

	public static void SendLog(boolean callInFuture, LogglyClientStep3.LogItem log){

		if(!isLogAllowed(log))
			return;

		if(callInFuture && !system.isFuture() && !system.isBatch()){
			SendLog(log.toJSON());
		} else{
			doCall(log.toJSON());
		}

	}

	@future(callout=true)
	private static void SendLog(String log){
		doCall(log);
	}

	public static List<LogglyClientStep3.LogItem> retrieveLogItems(String query, String fromWhen, String toWhen, String order, Integer size){

		String searchId = LogglyClientStep3.search(query, fromWhen, toWhen, order, size);
		String itemsStr = LogglyClientStep3.events(searchId);

		EventsResponse res = (EventsResponse)JSON.deserialize(itemsStr, EventsResponse.class);

		List<LogglyClientStep3.LogItem> ret = new List<LogglyClientStep3.LogItem>();

		for(Event evt : res.events)
			ret.add(evt.event.json);

		return ret;
	}

	private static void doCall(String log){

		try{
			HttpRequest req = new HttpRequest();
			req.setMethod('POST');
			req.setEndPoint('https://logs-01.loggly.com/inputs/3e2caffd-ad6d-4070-8324-387aff91440f');
			req.setHeader('Content-Type', 'application/json');
			req.setHeader('Content-Length', String.valueOf(log.length()));
			req.setBody(log);

			Http h = new Http();
			if(!Test.isRunningTest())
				h.send(req);

		}catch(Exception ex){}
	}


	public static string search(String query, String fromWhen, String toWhen, String order, Integer size){

		if(String.isBlank(query))
			return null;

		String endpoint = 'https://df13a.loggly.com/apiv2/search?q=' + query;
		if(!String.isBlank(fromWhen))
			endpoint += '&from=' + fromWhen;

		if(!String.isBlank(toWhen))
			endpoint += '&to=' + toWhen;

		if(!String.isBlank(order))
			endpoint += '&order=' + order;

		if(size != null && size >= 0)
			endpoint += '&size=' + size;


		LogglyCredentials__c cred = LogglyCredentials__c.getInstance(UserInfo.getOrganizationId());
		String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(cred.Username__c + ':' + cred.password__c));

		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint(endpoint);
		req.setHeader('Authorization', authHeader);

		String resBody = '{}';
		Http h = new Http();
		if(!Test.isRunningTest()){
			resBody = h.send(req).getBody();
		}

		searchResponse res = (searchResponse)JSON.deserialize(resBody, searchResponse.class);

		return res.rsid.id;

	}

	public static String events(String searchId){

		String endpoint = 'https://df13a.loggly.com/apiv2/events?rsid=' + searchId;

		LogglyCredentials__c cred = LogglyCredentials__c.getInstance(UserInfo.getOrganizationId());
		String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(cred.Username__c + ':' + cred.password__c));

		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint(endpoint);
		req.setHeader('Authorization', authHeader);

		String resBody = '{}';
		Http h = new Http();
		if(!Test.isRunningTest()){
			resBody = h.send(req).getBody();
		}

		return resBody;
	}

	private static boolean isLogAllowed(LogglyClientStep3.LogItem log){

		LoggingOptions__c opt = LoggingOptions__c.getInstance(UserInfo.getUserId());

		if(!opt.Main_Switch__c)
			return false;

		if(log.severity < opt.severity__c)
			return false;

		if(log.type == LogType.TRACE && !opt.traces__c)
			return false;

		if(log.type == LogType.ERROR && !opt.exceptions__c)
			return false;

		return true;

	}

	public class LogItem{

		public String application {get; set;}
		public Integer severity {get; set;}
		public LogType type {get; set;}
		public String location {get; set;}
		public String message {get; set;}
		public Exception thrownException {get; set;}
		public String orgId {get; private set;}
		public String userId {get; private set;}
		public DateTime timeStamp {get; private set;}
		
		public LogItem(){
			this.orgId = UserInfo.getOrganizationId();
			this.userId = UserInfo.getUserId();
			this.timeStamp = system.now();
		}

		public LogItem(String application, Integer severity, LogType type, String location, String message, Exception thrownException){
			this.application = application;
			this.severity = severity;
			this.type = type;
			this.location = location;
			this.message = message;
			this.thrownException = thrownException;
			this.orgId = UserInfo.getOrganizationId();
			this.userId = UserInfo.getUserId();
			this.timeStamp = system.now();
		}

		public String toJSON(){
			return JSON.serialize(this);
		}

	}

	public enum LogType{
		ERROR,
		TRACE
	}


	private class SearchResponse{
		rsidDetails rsid {get; set;}
	}

	private class rsidDetails{
		String id {get; set;}
	}


	private class EventsResponse{
		Integer total_events {get; set;}
		Integer page {get; set;}
		List<event> events {get; set;}

	}

	private class Event{
		Long timestamp {get; set;}
		String id {get; set;}
		EventBody event {get; set;}
	}

	private class EventBody{
		LogItem json {get; set;}
	}

}