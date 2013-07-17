package v9pf.events
{
	import flash.events.Event;
	
	public class ServerSocketEvent extends Event
	{
		public static const START:String = "ServerSocketEvent_START";
		public static const STOP:String = "ServerSocketEvent_STOP";
		
		public function ServerSocketEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}