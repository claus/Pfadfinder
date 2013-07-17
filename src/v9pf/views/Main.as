package v9pf.views
{
	import v9pf.views.components.V9Container;
	
	public class Main extends V9Container
	{
		public var header:Header;
		
		public function Main()
		{
			super();
		}

		override public function setSize(width:Number, height:Number):void
		{
			header.move(0, 0);
			header.setSize(width, 28);
		}
		
		override protected function init():void
		{
			header = new Header();
			addChild(header);
		}
	}
}
