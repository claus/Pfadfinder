package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.text.TextFormat;
	
	import fl.controls.Button;
	import fl.controls.Label;
	import fl.managers.StyleManager;
	
	import v9pf.V9Context;
	import v9pf.views.Main;
	
	public class Pfadfinder extends Sprite
	{
		public static var fontInconsolata:Inconsolata = new Inconsolata();

		private var view:Main;
		private var context:V9Context;

		public function Pfadfinder()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			var buttonDummy:Button = new Button();

			StyleManager.setComponentStyle(Button, "textFormat", new TextFormat("_sans", 12, 0x333333));
			StyleManager.setComponentStyle(Button, "disabledTextFormat", new TextFormat("_sans", 12, 0xaaaaaa));
			StyleManager.setComponentStyle(Label, "textFormat", new TextFormat("_sans", 12, 0x000000));
			
			context = new V9Context(this);
			
			view = new Main();
			addChild(view);
			
			if(stage) {
				stage.addEventListener(Event.RESIZE, resizeHandler);
				resize();
			} else {
				addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			}
		}

		protected function addedToStageHandler(event:Event):void
		{
			stage.addEventListener(Event.RESIZE, resizeHandler);
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			resize();
		}
		
		protected function resizeHandler(event:Event):void
		{
			resize();
		}
		
		protected function resize():void
		{
			view.setSize(stage.stageWidth, stage.stageHeight);
		}
	}
}
