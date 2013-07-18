package v9pf.models.vo.tlm
{
	public class TLMRegion extends TLMRect
	{
		public var name:String;
		public var symbolName:String;
		public var modified:Boolean;
		
		public function TLMRegion(amf:Object)
		{
			super(amf);
			name = amf.name;
			symbolName = amf.symbolname;
			modified = amf.modified;
		}
		
		public override function toString():String {
			return "[" + type + "] " + [xmin,ymin,width,height] + " " + toStringValues(["name", "symbolName", "modified" ]);
		}
	}
}