package v9pf.models
{
	import org.robotlegs.mvcs.Actor;
	
	import v9pf.models.vo.ClientSession;
	
	public class ClientSessionProxy extends Actor
	{
		protected var _sessions:Array;
		
		public function ClientSessionProxy()
		{
			super();
			_sessions = [];
		}
		
		public function get sessions():Array
		{
			return _sessions;
		}

		public function register(session:ClientSession):void
		{
			sessions.unshift(session);
			trace("ClientSessionProxy - session registered");
			//trace(session.getSessionItems(0).join("\n"));
		}
		
		public function getSessionByFilename(filePath:String):ClientSession
		{
			for each(var session:ClientSession in sessions) {
				if (session.meta.filePath == filePath) {
					return session;
				}
			}
			return null;
		}
	}
}
