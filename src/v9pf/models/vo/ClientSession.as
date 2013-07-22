package v9pf.models.vo
{
	import com.coursevector.amf.AMF3;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import v9pf.events.ClientSessionEvent;
	import v9pf.models.vo.tlm.TLM;
	import v9pf.models.vo.tlm.TLMFactory;
	import v9pf.models.vo.tlm.TLMSessionItem;

	public class ClientSession extends EventDispatcher
	{
		protected var _socket:Socket;
		
		protected var file:File;
		protected var fileStream:FileStream;
		
		protected var bytes:ByteArray;
		protected var amf3:AMF3;
		
		protected var lastPos:uint;
		protected var firstFrame:Boolean;
		protected var timeEndCurrent:Number;
		
		protected var sessionItems:Vector.<TLMSessionItem>;
		protected var frameIndices:Vector.<uint>;
		
		public function ClientSession(socket:Socket = null)
		{
			_socket = socket;
			
			bytes = new ByteArray();
			amf3 = new AMF3();
			lastPos = 0;
			firstFrame = true;
			timeEndCurrent = 0;
			
			sessionItems = new Vector.<TLMSessionItem>();
			frameIndices = new Vector.<uint>();

			addListeners();
		}
		
		public function get connected():Boolean
		{
			return (socket && socket.connected);
		}

		public function get numFrames():uint
		{
			return frameIndices.length;
		}
		
		public function get socket():Socket
		{
			return _socket;
		}

		public function getSessionItems(frameNr:uint):Vector.<TLMSessionItem>
		{
			if (frameNr < frameIndices.length) {
				var startIdx:uint = (frameNr > 0) ? frameIndices[frameNr - 1] : 0;
				var endIdx:uint = frameIndices[frameNr];
				return sessionItems.slice(startIdx, endIdx);
			}
			return new Vector.<TLMSessionItem>();
		}
		
		public function writeBytes(ba:ByteArray):void
		{
			bytes.writeBytes(ba);
			processBytes();
		}

		public function close():void
		{
			try {
				removeListeners();
				socket.close();
			}
			catch (e:Error) {
			}
			archiveStop();
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
			dispatchEvent(new ClientSessionEvent(ClientSessionEvent.CLOSED, this));
		}
		
		protected function socketIOError(event:IOErrorEvent):void
		{
			close();
			dispatchEvent(new ClientSessionEvent(ClientSessionEvent.CLOSED, this));
		}
		
		protected function processBytes():void
		{
			var oldPos:uint = bytes.position = lastPos;
			try {
				while(true) {
					amf3.deserialize(bytes, false);
					processObject(amf3.data);
					lastPos = bytes.position;
				}
			}
			catch(e:Error) {
				if (e.errorID != 2030) {
					trace(e);
				}
			}
			archive(oldPos, lastPos);
		}
		
		protected function processObject(obj:Object):void
		{
			var tlm:TLMSessionItem = TLMFactory.create(obj) as TLMSessionItem;
			if (tlm != null) {
				timeEndCurrent += (obj.delta != undefined) ? obj.delta : 0;
				tlm.timeTotal = (obj.span != undefined) ? obj.span : 0;
				tlm.timeBegin = timeEndCurrent - tlm.timeTotal;
				tlm.timeEnd = timeEndCurrent;
				addItem(tlm);
				//trace(tlm);
			} else {
				trace("Unable to create session item: " + JSON.stringify(obj));
			}
		}
		
		protected function addItem(tlm:TLMSessionItem):void
		{
			// ignore .enter and .exit items (until i figure out what they're good for)
			if ((tlm.type == TLM.TIME && tlm.name == ".enter") || (tlm.type == TLM.SPAN && tlm.name == ".exit")) {
				return;
			}
			// .value .swf.frame indicates that a new frame starts
			if (tlm.type == TLM.VALUE && tlm.name == ".swf.frame") {
				newFrame();
			}
			// .value
			if (tlm.type == TLM.VALUE) {
				processValues(tlm);
			}
			if (sessionItems.length > 0) {
				for (var i:int = sessionItems.length - 1; i >= 0; i--) {
					if (sessionItems[i].timeBegin <= tlm.timeBegin) {
						if (i == sessionItems.length - 1) {
							sessionItems.push(tlm);
						} else {
							sessionItems.splice(i + 1, 0, tlm);
						}
						break;
					}
				}
			} else {
				sessionItems.push(tlm);
			}
		}
		
		private function processValues(tlm:TLMSessionItem):void
		{
		}
		
		protected function newFrame():void
		{
			frameIndices.push(sessionItems.length);
			dispatchEvent(new ClientSessionEvent(ClientSessionEvent.NEW_FRAME, this));
			//trace(sessionItems.slice(frameIndices.length > 1 ? frameIndices[frameIndices.length - 2] : 0).join("\n"));
			if (firstFrame) {
				firstFrame = false;
				archiveStart();
			}
		}
		
		protected function archiveStart():void
		{
			if (socket) {
				file = File.createTempFile();
				fileStream = new FileStream();
				fileStream.openAsync(file, FileMode.WRITE);
			}
		}
		
		protected function archive(from:uint, to:uint):void
		{
			if (socket && file && fileStream) {
				fileStream.writeBytes(bytes, from, to - from);
			}
		}
		
		protected function archiveStop():void
		{
			if (socket && file && fileStream) {
				fileStream.addEventListener(Event.CLOSE, fileStreamCloseHandler);
				fileStream.close();
			}
		}
		
		protected function fileStreamCloseHandler(event:Event):void
		{
			// TODO: rename, move, store metadata
		}
	}
}
