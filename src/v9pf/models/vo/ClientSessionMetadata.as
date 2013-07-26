package v9pf.models.vo
{
	public class ClientSessionMetadata
	{
		public var filePath:String;
		
		public function ClientSessionMetadata(filePath:String = null)
		{
			super();
			this.filePath = filePath;
		}
	}
}