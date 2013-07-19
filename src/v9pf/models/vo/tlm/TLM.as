package v9pf.models.vo.tlm
{
	public class TLM
	{
		public static const UNKNOWN:String = "???";

		public static const VALUE:String = ".value";
		public static const TIME:String = ".time";
		public static const SPAN:String = ".span";
		public static const SPANVALUE:String = ".spanValue";

		public static const RECT:String = ".rect";
		public static const REGION:String = ".region";
		public static const SAMPLER_SAMPLE:String = "Sampler_sample";
		public static const MEMORY_OBJECTALLOCATION:String = ".memory.objectAllocation";
		public static const MEMORY_DEALLOCATION:String = ".memory.deallocation";
		
		private var _type:String;
		
		public function TLM(amf:Object)
		{
			_type = amf.__className;
		}

		public function get type():String { return _type; }
		
		public function toString():String {
			return "[" + type + "]";
		}
		
		protected function toStringValues(values:Array):String {
			var v:Array = [];
			for (var i:int = 0; i < values.length; i++) {
				v.push(values[i] + ": " + this[values[i]]);
			}
			return v.join(", ");
		}
	}
}
