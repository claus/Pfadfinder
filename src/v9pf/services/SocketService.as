package v9pf.services
{
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import org.robotlegs.mvcs.Actor;
	
	import v9pf.models.vo.ClientSession;
	
	public class SocketService extends Actor
	{
		private var serverSocket:ServerSocket;
		
		private var sessions:Vector.<ClientSession>;
		
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
					serverSocket.addEventListener(ServerSocketConnectEvent.CONNECT, connectHandler); 
					serverSocket.addEventListener(Event.CLOSE, closeHandler); 
					serverSocket.bind(7934, "127.0.0.1"); 
					serverSocket.listen(); 
				}
				catch (e:Error) {
					trace("SocketService START SOCKET failed:");
					trace(e);
				}
			}
		}
		
		public function stop():void
		{
			trace("SocketService STOP SOCKET");
			if (serverSocket) {
				serverSocket.close();
				serverSocket.removeEventListener(ServerSocketConnectEvent.CONNECT, connectHandler); 
				serverSocket.removeEventListener(Event.CLOSE, closeHandler); 
				serverSocket = null;
			}
			deleteConf();
		}
		
		private function connectHandler(event:ServerSocketConnectEvent):void 
		{ 
			trace("SocketService - client connected");
			var socket:Socket = event.socket as Socket;
			var session:ClientSession = new ClientSession(socket);
			sessions.push(session);
		} 
		
		private function closeHandler(event:Event):void 
		{ 
			trace("SocketService - socket closed by OS");
			//removeClient(event.target as Socket);
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
					return false;
				}
			}
			return true;
		}
	}
}
