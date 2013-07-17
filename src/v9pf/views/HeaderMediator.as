package v9pf.views
{
	import org.robotlegs.mvcs.Mediator;
	
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
			addViewListener(HeaderViewEvent.SOCKET_BTN_TOGGLE, socketBtnToggleHandler, HeaderViewEvent);
		}
		
		override public function onRemove():void
		{
			removeViewListener(HeaderViewEvent.SOCKET_BTN_TOGGLE, socketBtnToggleHandler, HeaderViewEvent);
		}

		/*
		private function btnLoadSWFClickHandler(event:MouseEvent):void
		{
			var ref:FileReference = new FileReference();
			ref.addEventListener(Event.SELECT, function(e:Event):void { ref.load(); });
			ref.addEventListener(Event.COMPLETE, function(e:Event):void {
				dispatch(new SWFEvent(SWFEvent.LOAD, ref.name, ref.data));
			});
			ref.browse([new FileFilter("SWF (*.swf)", "*.swf"), new FileFilter("SWC (*.swc)", "*.swc")]);
		}
		*/
		
		protected function socketBtnToggleHandler(event:HeaderViewEvent):void
		{
			var selected:Boolean = (event.data["selected"] == true);
			dispatch(new ServerSocketEvent(selected ? ServerSocketEvent.START : ServerSocketEvent.STOP));
		}
	}
}
