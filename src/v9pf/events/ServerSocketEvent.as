package v9pf.events
{
	import flash.events.Event;
	
	public class ServerSocketEvent extends Event
	{
		public static const START:String = "ServerSocketEvent_START";
		public static const STOP:String = "ServerSocketEvent_STOP";
		
		public static const STARTED:String = "ServerSocketEvent_STARTED";
		public static const STOPPED:String = "ServerSocketEvent_STOPPED";
		
		public function ServerSocketEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}