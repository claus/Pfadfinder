package v9pf.views
{
	import org.robotlegs.mvcs.Mediator;
	
	import v9pf.events.ServerSocketEvent;
	import v9pf.events.TelemetryFileEvent;
	import v9pf.views.events.HeaderViewEvent;

	public class HeaderMediator extends Mediator
	{
		[Inject]
		public var view:Header;
		
		public function HeaderMediator()
		{
			super();
		}
		
		override public function onRegister():void
		{
			addViewListener(HeaderViewEvent.LOAD_BTN_CLICK, loadBtnClickHandler, HeaderViewEvent);
			addViewListener(HeaderViewEvent.SOCKET_BTN_TOGGLE, socketBtnToggleHandler, HeaderViewEvent);
		}
		
		override public function onRemove():void
		{
			removeViewListener(HeaderViewEvent.LOAD_BTN_CLICK, loadBtnClickHandler, HeaderViewEvent);
			removeViewListener(HeaderViewEvent.SOCKET_BTN_TOGGLE, socketBtnToggleHandler, HeaderViewEvent);
		}

		protected function loadBtnClickHandler(event:HeaderViewEvent):void
		{
			dispatch(new TelemetryFileEvent(TelemetryFileEvent.LOAD));
		}
		
		protected function socketBtnToggleHandler(event:HeaderViewEvent):void
		{
			var selected:Boolean = (event.data["selected"] == true);
			dispatch(new ServerSocketEvent(selected ? ServerSocketEvent.START : ServerSocketEvent.STOP));
		}
	}
}
