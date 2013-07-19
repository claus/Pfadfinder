package v9pf.views
{
	import org.robotlegs.mvcs.Mediator;

	public class MainMediator extends Mediator
	{
		[Inject]
		public var view:Main;
		
		public function MainMediator()
		{
			super();
		}
		
		override public function onRegister():void
		{
		}
		
		override public function onRemove():void
		{
		}
	}
}
