package v9pf.commands
{
	import org.robotlegs.mvcs.Command;
	
	import v9pf.services.SocketService;
	
	public class ServerSocketStopCommand extends Command
	{
		[Inject]
		public var socketService:SocketService;
		
		public override function execute():void
		{
			socketService.stop();
		}
	}
}