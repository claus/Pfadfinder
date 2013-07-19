package v9pf.models.vo.tlm
{
	public class TLMMemoryObjectAllocation extends TLM
	{
		public var id:uint;
		public var stackid:uint;
		public var time:Number;
		public var size:uint;
		public var objecttype:String;
		
		public function TLMMemoryObjectAllocation(amf:Object)
		{
			super(amf);
			id = amf.id;
			stackid = amf.stackid;
			time = amf.time;
			size = amf.size;
			objecttype = amf.type;
		}
		
		public override function toString():String {
			return "[" + type + "] " + toStringValues(["id", "stackid", "time", "size", "objecttype" ]);
		}
	}
}