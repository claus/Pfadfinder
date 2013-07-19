package v9pf.models
{
	import org.robotlegs.mvcs.Actor;
	
	import v9pf.models.vo.ClientSession;
	
	public class ClientSessionProxy extends Actor
	{
		protected var sessions:Array;
		
		public function ClientSessionProxy()
		{
			super();
			sessions = [];
		}
		
		public function register(session:ClientSession):void
		{
			sessions.unshift(session);
			trace("ClientSessionProxy - session registered");
		}
	}
}
