package v9pf.models.vo.tlm
{
	public class TLMRect extends TLM
	{
		public var xmin:Number;
		public var xmax:Number;
		public var ymin:Number;
		public var ymax:Number;
		
		public function TLMRect(amf:Object)
		{
			super(amf);
			xmin = amf.xmin;
			xmax = amf.xmax;
			ymin = amf.ymin;
			ymax = amf.ymax;
		}
		
		public function get width():Number {
			return xmax - xmin;
		}
		public function get height():Number {
			return ymax - ymin;
		}
		
		public override function toString():String {
			return "[" + type + "] " + [xmin,ymin,width,height];
		}
	}
}