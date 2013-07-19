package v9pf.views.events
{
	import flash.events.Event;
	
	public class HeaderViewEvent extends Event
	{
		public static const LOAD_BTN_CLICK:String = "HeaderViewEvent_LOAD_BTN_CLICK";
		public static const SOCKET_BTN_TOGGLE:String = "HeaderViewEvent_SOCKET_BTN_TOGGLE";
		
		public var data:Object;
		
		public function HeaderViewEvent(type:String, data:Object = null, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}
	}
}