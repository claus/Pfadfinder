package v9pf.models.vo.tlm
{
	public class TLMSessionItem extends TLM
	{
		public var name:String;
		public var value:*;

		public var timeBegin:Number;
		public var timeEnd:Number;
		public var timeTotal:Number;
		public var timeSelf:Number;
		
		public function TLMSessionItem(amf:Object)
		{
			super(amf);
			name = amf.name;
			value = (amf.value is Object && typeof amf.value == "object") ? TLMFactory.create(amf.value) : amf.value;
		}
		
		public override function toString():String {
			var val:String = (value != null && value != undefined) ? ": " + value.toString() : "";
			return timeBegin + "-" + timeEnd + " [" + type + "] " + name + val;
		}
	}
}
