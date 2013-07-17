package v9pf.views.components
{
	import flash.display.Sprite;
	
	public class V9Container extends Sprite
	{
		protected var _w:Number;
		protected var _h:Number;
		
		protected var _styles:Object;
		
		public function V9Container(styles:Object = null)
		{
			initStyles(styles);
			init();
		}
		
		protected function initStyles(styles:Object):void
		{
			_styles = { border: {} };
			if(styles != null) {
				if(styles.backgroundColor != undefined) {
					_styles.background = {
						color: styles.backgroundColor,
						alpha: (styles.backgroundAlpha != undefined) ? styles.backgroundColor : 1
					};
				}
				if(styles.borderColor != undefined) {
					_styles.border = {
						top: { color: styles.backgroundColor, alpha: 1 },
						right: { color: styles.backgroundColor, alpha: 1 },
						bottom: { color: styles.backgroundColor, alpha: 1 },
						left: { color: styles.backgroundColor, alpha: 1 }
					};
					if(styles.borderAlpha != undefined) {
						_styles.border.top.alpha =
						_styles.border.right.alpha = 
						_styles.border.bottom.alpha = 
						_styles.border.left.alpha = styles.borderAlpha;
					}
				}
				if(styles.borderTopColor != undefined) {
					if(_styles.border.top) {
						_styles.border.top.color = styles.borderTopColor;
					} else {
						_styles.border.top = { color: styles.borderTopColor, alpha: 1 };
					}
					_styles.border.top.alpha = (styles.borderTopAlpha != undefined) ? styles.borderTopAlpha : 1;
				}
				if(styles.borderRightColor != undefined) {
					if(_styles.border.right) {
						_styles.border.right.color = styles.borderRightColor;
					} else {
						_styles.border.right = { color: styles.borderRightColor, alpha: 1 };
					}
					_styles.border.right.alpha = (styles.borderRightAlpha != undefined) ? styles.borderRightAlpha : 1;
				}
				if(styles.borderBottomColor != undefined) {
					if(_styles.border.bottom) {
						_styles.border.bottom.color = styles.borderBottomColor;
					} else {
						_styles.border.bottom = { color: styles.borderBottomColor, alpha: 1 };
					}
					_styles.border.bottom.alpha = (styles.borderBottomAlpha != undefined) ? styles.borderBottomAlpha : 1;
				}
				if(styles.borderLeftColor != undefined) {
					if(_styles.border.left) {
						_styles.border.left.color = styles.borderLeftColor;
					} else {
						_styles.border.left = { color: styles.borderLeftColor, alpha: 1 };
					}
					_styles.border.left.alpha = (styles.borderLeftAlpha != undefined) ? styles.borderLeftAlpha : 1;
				}
			}
		}
		
		protected function init():void
		{
		}
		
		public function move(px:Number, py:Number):void
		{
			x = px;
			y = py;
		}
		
		public function setSize(width:Number, height:Number):void
		{
			if(!isNaN(width) && !isNaN(height) && (_w != width || _h != height)) {
				_w = width;
				_h = height;
				if(_styles.background) {
					var x:Number = _styles.border.left ? 1 : 0;
					var y:Number = _styles.border.top ? 1 : 0;
					var w:Number = _styles.border.right ? width - x - 1 : width - x;
					var h:Number = _styles.border.bottom ? height - y - 1 : height - y;
					graphics.beginFill(_styles.background.color, _styles.background.alpha);
					graphics.drawRect(x, y, w, h);
					graphics.endFill();
				}
				if(_styles.border.top) {
					graphics.beginFill(_styles.border.top.color, _styles.border.top.alpha);
					graphics.drawRect(0, 0, width, 1);
					graphics.endFill();
				}
				if(_styles.border.left) {
					graphics.beginFill(_styles.border.left.color, _styles.border.left.alpha);
					graphics.drawRect(0, 0, 1, height);
					graphics.endFill();
				}
				if(_styles.border.bottom) {
					graphics.beginFill(_styles.border.bottom.color, _styles.border.bottom.alpha);
					graphics.drawRect(0, height - 1, width, 1);
					graphics.endFill();
				}
				if(_styles.border.right) {
					graphics.beginFill(_styles.border.right.color, _styles.border.right.alpha);
					graphics.drawRect(width - 1, 0, 1, height);
					graphics.endFill();
				}
			}
		}

		public function resize():void
		{
			setSize(_w, _h);
		}
	}
}