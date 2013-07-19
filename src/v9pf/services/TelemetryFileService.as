package v9pf.services
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;
	
	import org.robotlegs.mvcs.Actor;
	
	import v9pf.events.ClientSessionEvent;
	import v9pf.models.vo.ClientSession;
	
	public class TelemetryFileService extends Actor
	{
		protected var session:ClientSession;
		
		public function TelemetryFileService()
		{
			super();
		}
		
		public function load():void
		{
			var file:File = new File();
			file.addEventListener(Event.SELECT, fileSelectHandler);
			file.browseForOpen("Open Telemetry (.flm) file", [ new FileFilter("FLM (*.flm)", "*.flm") ]);
		}
		
		protected function fileSelectHandler(event:Event):void
		{
			var file:File = event.target as File;
			var fileStream:FileStream = new FileStream();
			session = new ClientSession();
			session.addEventListener(ClientSessionEvent.NEW_FRAME, sessionNewFrameHandler);
			fileStream.addEventListener(ProgressEvent.PROGRESS, fileReadProgressHandler);
			fileStream.addEventListener(Event.COMPLETE, fileReadCompleteHandler);
			fileStream.openAsync(file, FileMode.READ);
		}
		
		protected function fileReadProgressHandler(event:ProgressEvent):void
		{
			var ba:ByteArray = new ByteArray();
			var fileStream:FileStream = event.target as FileStream;
			fileStream.readBytes(ba);
			if (ba.length > 0) {
				trace("read", ba.length, "bytes");
				session.writeBytes(ba);
			}
		}
		
		protected function fileReadCompleteHandler(event:Event):void
		{
			var fileStream:FileStream = event.target as FileStream;
			fileStream.close();
		}
		
		protected function sessionNewFrameHandler(event:ClientSessionEvent):void
		{
			trace("TelemetryFileService - first frame received");
			session.removeEventListener(ClientSessionEvent.NEW_FRAME, sessionNewFrameHandler);
			dispatch(new ClientSessionEvent(ClientSessionEvent.REGISTER, session));
		}
	}
}
