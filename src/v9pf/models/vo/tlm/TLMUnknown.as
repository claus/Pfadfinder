package v9pf.models.vo.tlm
{
	public class TLMUnknown extends TLM
	{
		public var data:Object;
		
		public function TLMUnknown(amf:Object)
		{
			super(amf);
			data = amf;
		}
		
		public override function get type():String { return TLM.UNKNOWN; }

		public override function toString():String {
			return "[" + type + "] " + JSON.stringify(data);
		}
	}
}
