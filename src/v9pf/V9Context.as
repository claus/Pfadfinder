package v9pf
{
	import flash.display.DisplayObjectContainer;
	
	import org.robotlegs.mvcs.Context;
	
	import v9pf.commands.ClientSessionFileLoadCommand;
	import v9pf.commands.ClientSessionFileSaveCommand;
	import v9pf.commands.ClientSessionFileSelectCommand;
	import v9pf.commands.ClientSessionRegisterCommand;
	import v9pf.commands.ServerSocketStartCommand;
	import v9pf.commands.ServerSocketStopCommand;
	import v9pf.events.ClientSessionEvent;
	import v9pf.events.ServerSocketEvent;
	import v9pf.models.ClientSessionProxy;
	import v9pf.services.SocketService;
	import v9pf.services.TelemetryFileService;
	import v9pf.views.Header;
	import v9pf.views.HeaderMediator;
	import v9pf.views.Main;
	import v9pf.views.MainMediator;
	
	public class V9Context extends Context
	{
		public function V9Context(contextView:DisplayObjectContainer = null, autoStartup:Boolean = true)
		{
			super(contextView, autoStartup);
		}
		
		override public function startup():void
		{
			commandMap.mapEvent(ServerSocketEvent.START, ServerSocketStartCommand, ServerSocketEvent);
			commandMap.mapEvent(ServerSocketEvent.STOP, ServerSocketStopCommand, ServerSocketEvent);
			commandMap.mapEvent(ClientSessionEvent.REGISTER, ClientSessionRegisterCommand, ClientSessionEvent);
			commandMap.mapEvent(ClientSessionEvent.SELECT_FILE, ClientSessionFileSelectCommand, ClientSessionEvent);
			commandMap.mapEvent(ClientSessionEvent.LOAD_FILE, ClientSessionFileLoadCommand, ClientSessionEvent);
			commandMap.mapEvent(ClientSessionEvent.SAVE_FILE, ClientSessionFileSaveCommand, ClientSessionEvent);
			
			injector.mapSingleton(ClientSessionProxy);
			injector.mapSingleton(SocketService);
			injector.mapSingleton(TelemetryFileService);
			
			mediatorMap.mapView(Main, MainMediator);
			mediatorMap.mapView(Header, HeaderMediator);
			
			// Startup complete
			super.startup();
		}
	}
}
