package v9pf.events
{
	import flash.events.Event;
	
	import v9pf.models.vo.ClientSession;
	
	public class ClientSessionEvent extends Event
	{
		public static const CLOSED:String = "ClientSessionEvent_CLOSED";
		public static const NEW_FRAME:String = "ClientSessionEvent_NEW_FRAME";
		public static const REGISTER:String = "ClientSessionEvent_REGISTER";
		
		public var session:ClientSession;
		
		public function ClientSessionEvent(type:String, session:ClientSession, bubbles:Boolean = false, cancelable:Boolean = false)
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