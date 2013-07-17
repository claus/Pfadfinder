package v9pf.models.vo
{
	import com.coursevector.amf.AMF3;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;

	public class ClientSession extends EventDispatcher
	{
		protected var socket:Socket;
		protected var bytes:ByteArray;
		protected var amf3:AMF3;
		
		protected var lastPos:uint;
		
		public function ClientSession(socket:Socket = null)
		{
			this.socket = socket;
			
			bytes = new ByteArray();
			amf3 = new AMF3();
			lastPos = 0;

			addListeners();
		}
		
		public function get connected():Boolean
		{
			return (socket && socket.connected);
		}

		public function close():void
		{
			try {
				removeListeners();
				socket.close();
			}
			catch (e:Error) {
			}
			socket = null;
		}
		
		protected function addListeners():void
		{
			if (socket) {
				socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
				socket.addEventListener(Event.CLOSE, socketCloseHandler);
				socket.addEventListener(IOErrorEvent.IO_ERROR, socketIOError);
			}
		}
		
		protected function removeListeners():void
		{
			if (socket) {
				socket.removeEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
				socket.removeEventListener(Event.CLOSE, socketCloseHandler);
				socket.removeEventListener(IOErrorEvent.IO_ERROR, socketIOError);
			}
		}
		
		protected function socketDataHandler(event:ProgressEvent):void
		{
			socket.readBytes(bytes, bytes.length);
			processBytes();
		}
		
		protected function socketCloseHandler(event:Event):void
		{
			close();
		}
		
		protected function socketIOError(event:IOErrorEvent):void
		{
			close();
		}
		
		protected function processBytes():void
		{
			bytes.position = lastPos;
			try {
				while(true) {
					amf3.deserialize(bytes, false);
					processObject(amf3.data);
					lastPos = bytes.position;
				}
			}
			catch(e:Error) {
				if (e.errorID != 2030) {
					trace("#########################");
					trace(e);
					trace("#########################");
				}
			}
		}
		
		protected function processObject(obj:Object):void
		{
			trace(JSON.stringify(obj));
		}
	}
}
