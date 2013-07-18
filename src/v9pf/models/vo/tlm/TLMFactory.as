package v9pf.models.vo.tlm
{
	public class TLMFactory
	{
		public static function create(amf:Object):TLM
		{
			var tlm:TLM;
			
			switch (amf.__className) {
				case TLM.VALUE:
				case TLM.TIME:
				case TLM.SPAN:
				case TLM.SPANVALUE:
					tlm = new TLMSessionItem(amf);
					break;
				case TLM.RECT:
					tlm = new TLMRect(amf);
					break;
				case TLM.REGION:
					tlm = new TLMRegion(amf);
					break;
				default:
					tlm = new TLMUnknown(amf);
					break;
			}
			
			return tlm;
		}
	}
}
