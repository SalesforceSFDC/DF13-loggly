public with sharing class LogglyClientStep1 {

	public static void SendLog(boolean callInFuture, LogglyClientStep1.LogItem log){

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

	//LogglyClientStep1.SendLog(false, new LogglyClientStep1.LogItem('Test App', 20, LogglyClientStep1.LogType.TRACE, 'Debug Console', 'This is a test', null));

}