package v9pf.views
{
	import org.robotlegs.mvcs.Mediator;
	
	import v9pf.events.ClientSessionEvent;
	import v9pf.events.ServerSocketEvent;
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
			addContextListener(ServerSocketEvent.STARTED, socketStarted, ServerSocketEvent);
			addContextListener(ServerSocketEvent.STOPPED, socketStopped, ServerSocketEvent);
		}
		
		override public function onRemove():void
		{
			removeViewListener(HeaderViewEvent.LOAD_BTN_CLICK, loadBtnClickHandler, HeaderViewEvent);
			removeViewListener(HeaderViewEvent.SOCKET_BTN_TOGGLE, socketBtnToggleHandler, HeaderViewEvent);
			removeContextListener(ServerSocketEvent.STARTED, socketStarted, ServerSocketEvent);
			removeContextListener(ServerSocketEvent.STOPPED, socketStopped, ServerSocketEvent);
		}
		
		protected function loadBtnClickHandler(event:HeaderViewEvent):void
		{
			dispatch(new ClientSessionEvent(ClientSessionEvent.SELECT_FILE));
		}
		
		protected function socketBtnToggleHandler(event:HeaderViewEvent):void
		{
			var selected:Boolean = (event.data["selected"] == true);
			dispatch(new ServerSocketEvent(selected ? ServerSocketEvent.START : ServerSocketEvent.STOP));
		}
		
		protected function socketStarted(event:ServerSocketEvent):void
		{
			view.btnSocketSelected = true;
		}
		
		protected function socketStopped(event:ServerSocketEvent):void
		{
			view.btnSocketSelected = false;
		}
	}
}
