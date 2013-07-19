package v9pf.commands
{
	import org.robotlegs.mvcs.Command;
	
	import v9pf.events.ClientSessionEvent;
	import v9pf.models.ClientSessionProxy;
	
	public class ClientSessionRegisterCommand extends Command
	{
		[Inject]
		public var clientSessionProxy:ClientSessionProxy;

		[Inject]
		public var event:ClientSessionEvent;
		
		public override function execute():void
		{
			clientSessionProxy.register(event.session);
		}
	}
}
