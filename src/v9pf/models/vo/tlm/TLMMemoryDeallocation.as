package v9pf.models.vo.tlm
{
	public class TLMMemoryDeallocation extends TLM
	{
		public var id:uint;
		public var time:Number;
		
		public function TLMMemoryDeallocation(amf:Object)
		{
			super(amf);
			id = amf.id;
			time = amf.time;
		}
		
		public override function toString():String {
			return "[" + type + "] " + toStringValues(["id", "time" ]);
		}
	}
}