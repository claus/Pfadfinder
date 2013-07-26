package v9pf.commands
{
	import org.robotlegs.mvcs.Command;
	
	import v9pf.events.ClientSessionEvent;
	import v9pf.services.TelemetryFileService;
	
	public class ClientSessionFileSaveCommand extends Command
	{
		[Inject]
		public var telemetryFileService:TelemetryFileService;
		
		[Inject]
		public var event:ClientSessionEvent;
		
		public override function execute():void
		{
			telemetryFileService.save(event.session);
		}
	}
}
