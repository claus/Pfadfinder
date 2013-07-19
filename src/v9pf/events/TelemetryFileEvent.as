package v9pf.events
{
	import flash.events.Event;
	
	public class TelemetryFileEvent extends Event
	{
		public static const LOAD:String = "TelemetryFileEvent_LOAD";
		
		public function TelemetryFileEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
