package v9pf.commands
{
	import org.robotlegs.mvcs.Command;
	
	import v9pf.services.TelemetryFileService;
	
	public class TelemetryFileLoadCommand extends Command
	{
		[Inject]
		public var telemetryFileService:TelemetryFileService;
		
		public override function execute():void
		{
			telemetryFileService.load();
		}
	}
}
