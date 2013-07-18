package v9pf.models.vo.tlm
{
	public class TLMFactory
	{
		public static function create(amf:Object):TLM
		{
			var tlm:TLM;
			
			if (amf is Object && amf.hasOwnProperty("__className")) {
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
					case TLM.SAMPLER_SAMPLE:
						tlm = new TLMSamplerSample(amf);
						break;
					default:
						tlm = new TLMUnknown(amf);
						break;
				}
			}
			
			return tlm;
		}
	}
}
