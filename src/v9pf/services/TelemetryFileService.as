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
	import v9pf.models.ClientSessionProxy;
	import v9pf.models.vo.ClientSession;
	import v9pf.models.vo.ClientSessionMetadata;
	
	public class TelemetryFileService extends Actor
	{
		[Inject]
		public var clientSessionProxy:ClientSessionProxy;
		
		public function TelemetryFileService()
		{
			super();
		}
		
		public function select():void
		{
			var file:File = new File();
			file.addEventListener(Event.SELECT, function(event:Event):void {
				var selectedFile:File = event.target as File;
				var session:ClientSession = clientSessionProxy.getSessionByFilename(selectedFile.nativePath);
				if (session == null) {
					session = new ClientSession(new ClientSessionMetadata(selectedFile.nativePath));
				}
				dispatch(new ClientSessionEvent(ClientSessionEvent.LOAD_FILE, session));
			});
			file.browseForOpen("Open Telemetry (.flm) file", [ new FileFilter("FLM (*.flm)", "*.flm") ]);
		}

		public function load(session:ClientSession):void
		{
			session.addEventListener(ClientSessionEvent.RECEIVED_FRAME, sessionNewFrameHandler);
			trace("TelemetryFileService - file reading:", session.meta.filePath);
			var file:File = new File(session.meta.filePath);
			var fileStream:FileStream = new FileStream();
			fileStream.addEventListener(ProgressEvent.PROGRESS, function(event:ProgressEvent):void {
				var ba:ByteArray = new ByteArray();
				fileStream.readBytes(ba);
				if (ba.length > 0) {
					session.writeBytes(ba);
				}
			}, false, 0, true);
			fileStream.addEventListener(Event.COMPLETE, function(event:Event):void {
				trace("TelemetryFileService - file closed:", session.meta.filePath, " (" + file.size + " bytes read)");
				fileStream.close();
			}, false, 0, true);
			fileStream.openAsync(file, FileMode.READ);
		}

		public function save(session:ClientSession):void
		{
			var file:File = File.createTempFile();
			var fileStream:FileStream = new FileStream();
			var ba:ByteArray = new ByteArray();
			session.readBytes(ba);
			fileStream.addEventListener(Event.CLOSE, function(event:Event):void {
				trace("TelemetryFileService - file closed:", file.nativePath, " (" + file.size + " bytes written)");
			}, false, 0, true);
			trace("TelemetryFileService - file saving:", file.nativePath);
			fileStream.openAsync(file, FileMode.WRITE);
			fileStream.writeBytes(ba);
			fileStream.close();
		}
		
		protected function sessionNewFrameHandler(event:ClientSessionEvent):void
		{
			trace("TelemetryFileService - first frame received");
			event.session.removeEventListener(ClientSessionEvent.RECEIVED_FRAME, sessionNewFrameHandler);
			dispatch(new ClientSessionEvent(ClientSessionEvent.REGISTER, event.session));
		}
	}
}
