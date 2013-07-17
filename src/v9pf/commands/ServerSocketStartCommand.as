package v9pf.commands
{
	import org.robotlegs.mvcs.Command;
	
	import v9pf.services.SocketService;
	
	public class ServerSocketStartCommand extends Command
	{
		[Inject]
		public var socketService:SocketService;
		
		public override function execute():void
		{
			socketService.start();
		}
	}
}