package v9pf.views
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextFormat;
	
	import fl.controls.Button;
	import fl.controls.ButtonLabelPlacement;
	import fl.controls.Label;
	
	import v9pf.views.components.V9Container;
	import v9pf.views.events.HeaderViewEvent;
	
	public class Header extends V9Container
	{
		public var lblFileName:Label;
		
		public var btnLoadFLM:Button;
		public var btnSocket:Button;
		
		public function Header()
		{
			super();
		}
		
		override public function setSize(width:Number, height:Number):void
		{
			super.setSize(width, height);
			
			var btnSocketWidth:Number = btnSocket.textField.textWidth + 20 + 18;
			btnSocket.setSize(btnSocketWidth, 28);
			btnSocket.move(width - btnSocketWidth, 0);
			
			var btnLoadFLMWidth:Number = btnLoadFLM.textField.textWidth + 20;
			btnLoadFLM.setSize(btnLoadFLMWidth, 28);
			btnLoadFLM.move(width - btnLoadFLMWidth - btnSocketWidth, 0);

			lblFileName.move(5, 4);
			lblFileName.setSize(width - btnLoadFLMWidth - 5, height - 4);
		}
		
		override protected function init():void
		{
			super.init();
			
			lblFileName = new Label();
			lblFileName.setStyle("textFormat", new TextFormat("_sans", 12, 0x333333));
			lblFileName.htmlText = "<font size='14'><b>V9</b></font> <font color='#888888'>Pfadfinder.</font>";
			addChild(lblFileName);
			
			btnLoadFLM = new Button();
			btnLoadFLM.addEventListener(MouseEvent.CLICK, btnLoadFLMClickHandler, false, 0, true);
			setButtonStyles(btnLoadFLM);
			btnLoadFLM.label = "Load Telemetry File";
			btnLoadFLM.drawNow();
			addChild(btnLoadFLM);
			
			btnSocket = new Button();
			btnSocket.addEventListener(Event.CHANGE, btnSocketChangeHandler, false, 0, true);
			btnSocket.toggle = true;
			setToggleButtonStyles(btnSocket);
			btnSocket.label = "Record Telemetry Data";
			btnSocket.drawNow();
			addChild(btnSocket);
		}
		
		protected function btnLoadFLMClickHandler(event:MouseEvent):void
		{
			dispatchEvent(new HeaderViewEvent(HeaderViewEvent.LOAD_BTN_CLICK));
		}

		protected function btnSocketChangeHandler(event:Event):void
		{
			dispatchEvent(new HeaderViewEvent(HeaderViewEvent.SOCKET_BTN_TOGGLE, { selected: btnSocket.selected }));
		}
		
		protected function setButtonStyles(btn:Button):void
		{
			btn.setStyle("upSkin", Button_leftBorder_upSkin);
			btn.setStyle("overSkin", Button_leftBorder_overSkin);
			btn.setStyle("downSkin", Button_leftBorder_downSkin);
			btn.setStyle("disabledSkin", Button_leftBorder_disabledSkin);
			btn.setStyle("selectedUpSkin", Button_leftBorder_selectedUpSkin);
			btn.setStyle("selectedOverSkin", Button_leftBorder_selectedOverSkin);
			btn.setStyle("selectedDownSkin", Button_leftBorder_selectedDownSkin);
			btn.setStyle("selectedDisabledSkin", Button_leftBorder_selectedDisabledSkin);
		}
		
		protected function setToggleButtonStyles(btn:Button):void
		{
			setButtonStyles(btn);
			btn.labelPlacement = ButtonLabelPlacement.LEFT;
			btn.setStyle("upIcon", ToggleButton_icon);
			btn.setStyle("overIcon", ToggleButton_icon);
			btn.setStyle("downIcon", ToggleButton_icon);
			btn.setStyle("disabledIcon", ToggleButton_icon);
			btn.setStyle("selectedUpIcon", ToggleButton_selectedIcon);
			btn.setStyle("selectedOverIcon", ToggleButton_selectedIcon);
			btn.setStyle("selectedDownIcon", ToggleButton_selectedIcon);
			btn.setStyle("selectedDisabledIcon", ToggleButton_selectedIcon);
			btn.setStyle("upSkin", Button_leftBorder_upSkin);
			btn.setStyle("overSkin", Button_leftBorder_overSkin);
			btn.setStyle("downSkin", Button_leftBorder_downSkin);
			btn.setStyle("disabledSkin", Button_leftBorder_disabledSkin);
			btn.setStyle("selectedUpSkin", Button_leftBorder_upSkin);
			btn.setStyle("selectedOverSkin", Button_leftBorder_overSkin);
			btn.setStyle("selectedDownSkin", Button_leftBorder_downSkin);
			btn.setStyle("selectedDisabledSkin", Button_leftBorder_disabledSkin);
		}
	}
}