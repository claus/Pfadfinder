package v9pf.events
{
	import flash.events.Event;
	
	import v9pf.models.vo.ClientSession;
	
	public class ClientSessionEvent extends Event
	{
		public static const CLOSED:String = "ClientSessionEvent_CLOSED";
		public static const RECEIVED_FRAME:String = "ClientSessionEvent_RECEIVED_FRAME";

		public static const REGISTER:String = "ClientSessionEvent_REGISTER";
		public static const SELECT_FILE:String = "ClientSessionEvent_SELECT_FILE";
		public static const LOAD_FILE:String = "ClientSessionEvent_LOAD_FILE";
		public static const SAVE_FILE:String = "ClientSessionEvent_SAVE_FILE";
		
		public var session:ClientSession;
		
		public function ClientSessionEvent(type:String, session:ClientSession = null, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			this.session = session;
		}
		
		public override function clone():Event
		{
			return new ClientSessionEvent(type, session, bubbles, cancelable);
		}
	}
}