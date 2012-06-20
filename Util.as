package {
	public class Util {
		import flash.utils.*;

		public static var uid:Number = 0;
		public static var entities:Entities = new Entities();

		public static function getUniqueID():Number {
			return ++uid;
		}

		private static function update():void {
			entities.update();
		}

		public static function initialize():void {
			setInterval(update, 1000/30);
		}
	}
}
