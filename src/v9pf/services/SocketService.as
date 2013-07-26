package v9pf.services
{
	import flash.events.Event;
	import flash.events.ServerSocketConnectEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import org.robotlegs.mvcs.Actor;
	
	import v9pf.events.ClientSessionEvent;
	import v9pf.events.ServerSocketEvent;
	import v9pf.models.vo.ClientSession;
	import v9pf.models.vo.ClientSessionMetadata;
	
	public class SocketService extends Actor
	{
		private var serverSocket:ServerSocket;
		
		private var sessions:Vector.<ClientSession>;
		
		private var connectionAttempts:uint = 0;
		private var connectionAttemptTimeoutID:uint = 0;
		
		private static const CONF_FILE:String = ".telemetry.cfg";
		
		public function SocketService()
		{
			super();
			sessions = new Vector.<ClientSession>();
		}
		
		public function start():void
		{
			trace("SocketService START SOCKET");
			if (writeConf()) {
				try {
					serverSocket = new ServerSocket(); 
					serverSocket.bind(7934, "127.0.0.1"); 
					serverSocket.addEventListener(ServerSocketConnectEvent.CONNECT, connectHandler); 
					serverSocket.addEventListener(Event.CLOSE, closeHandler); 
					serverSocket.listen();
					connectionAttempts = 0;
					dispatch(new ServerSocketEvent(ServerSocketEvent.STARTED));
				}
				catch (e:Error) {
					trace("SocketService START SOCKET failed:", e);
					deleteConf();
					if (++connectionAttempts < 60) {
						connectionAttemptTimeoutID = setTimeout(start, 1000);
					} else {
						connectionAttempts = 0;
					}
				}
			}
		}
		
		public function stop():void
		{
			trace("SocketService STOP SOCKET");
			if (serverSocket) {
				try {
					removeAllClientSessions();
					serverSocket.close();
					serverSocket.removeEventListener(ServerSocketConnectEvent.CONNECT, connectHandler); 
					serverSocket.removeEventListener(Event.CLOSE, closeHandler); 
					serverSocket = null;
					clearTimeout(connectionAttemptTimeoutID);
					dispatch(new ServerSocketEvent(ServerSocketEvent.STOPPED));
				}
				catch (e:Error) {
					trace("SocketService STOP SOCKET failed:", e);
				}
			}
			deleteConf();
		}
		
		private function connectHandler(event:ServerSocketConnectEvent):void 
		{ 
			trace("SocketService - client connected");
			var socket:Socket = event.socket as Socket;
			var session:ClientSession = new ClientSession(new ClientSessionMetadata(), socket);
			session.addEventListener(ClientSessionEvent.RECEIVED_FRAME, sessionNewFrameHandler);
			session.addEventListener(ClientSessionEvent.CLOSED, sessionClosedHandler);
			sessions.push(session);
		} 
		
		private function closeHandler(event:Event):void 
		{ 
			trace("SocketService - socket closed by OS");
			removeAllClientSessions();
		}
		
		private function sessionNewFrameHandler(event:ClientSessionEvent):void
		{
			trace("SocketService - first frame received from client");
			dispatch(new ClientSessionEvent(ClientSessionEvent.REGISTER, event.session));
			event.session.removeEventListener(ClientSessionEvent.RECEIVED_FRAME, sessionNewFrameHandler);
		}

		private function sessionClosedHandler(event:ClientSessionEvent):void
		{
			trace("SocketService - client disconnected");
			removeClientSession(event.session);
		}
		
		private function removeClientSession(session:ClientSession):void
		{
			var i:uint = sessions.indexOf(session);
			if (i > -1) {
				if (session.numFrames > 0) {
					dispatch(new ClientSessionEvent(ClientSessionEvent.SAVE_FILE, session));
				}
				session.removeEventListener(ClientSessionEvent.RECEIVED_FRAME, sessionNewFrameHandler);
				session.removeEventListener(ClientSessionEvent.CLOSED, sessionClosedHandler);
				sessions.splice(i, 1);
				trace("SocketService - client removed");
			}
		}

		private function removeAllClientSessions():void
		{
			while (sessions.length > 0) {
				var session:ClientSession = sessions[0];
				session.close();
				removeClientSession(session);
			}
		}
		
		private function writeConf():Boolean
		{
			var file:File = File.userDirectory.resolvePath(CONF_FILE);
			if (file.exists) {
				// warn user?
				// return false;
			}
			var fs:FileStream  = new FileStream();
			try {
				fs.open(file, FileMode.WRITE);
				fs.writeUTFBytes("DisplayObjectCapture = true" + File.lineEnding);
				fs.writeUTFBytes("ScriptObjectAllocationTraces = false" + File.lineEnding);
				fs.writeUTFBytes("CPUCapture = true" + File.lineEnding);
				fs.writeUTFBytes("Stage3DCapture = false" + File.lineEnding);
				fs.writeUTFBytes("SamplerEnabled = false" + File.lineEnding);
				fs.writeUTFBytes("TelemetryAddress = localhost:7934" + File.lineEnding);
				fs.close();
			}
			catch (e:Error) {
				trace("SocketService - writing .telemetry.cfg failed:");
				trace(e);
				return false;
			}
			return true;
		}
		
		private function deleteConf():Boolean
		{
			var file:File = File.userDirectory.resolvePath(CONF_FILE);
			if (file.exists) {
				try {
					file.deleteFile();
				}
				catch (e:Error) {
					trace("SocketService - removing .telemetry.cfg failed:");
					trace(e);
					return false;
				}
			}
			return true;
		}
	}
}
