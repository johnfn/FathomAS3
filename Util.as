package {
	public class Util {
		public static var uid:Number = 0;
		public static var entities:Entities = new Entities();

		public static function getUniqueID():Number {
			return ++uid;
		}
	}
}
