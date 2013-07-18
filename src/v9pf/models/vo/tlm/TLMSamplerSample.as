package v9pf.models.vo.tlm
{
	public class TLMSamplerSample extends TLM
	{
		public var time:Number;
		public var numticks:uint;
		public var ticktimes:Array;
		public var callstack:Array;
		
		public function TLMSamplerSample(amf:Object)
		{
			super(amf);
			time = amf.time;
			numticks = amf.numticks;
			ticktimes = amf.ticktimes;
			callstack = amf.callstack;
		}
		
		public override function toString():String {
			return "[" + type + "] " + toStringValues(["time", "numticks", "ticktimes", "callstack" ]);
		}
	}
}