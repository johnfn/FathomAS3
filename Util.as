package {
	public class Util {
		import flash.utils.*;

		public static var uid:Number = 0;
		public static var entities:Entities = new Entities();

		public static function getUniqueID():Number {
			return ++uid;
		}

		public static function make2DArray(width:int, height:int, defaultValue:*):Array {
			var result:Array = new Array(width);

			for (var i:int = 0; i < width; i++) {
				result[i] = new Array(height);
				for (var j:int = 0; j < height; j++) {
					result[i][j] = defaultValue;
				}
			}

			return result;
		}

		public static function randRange(low, high) {
			return low + Math.floor(Math.random() * (high - low));
		}

		private static function update():void {
			entities.update();
		}

		public static function initialize():void {
			setInterval(update, 1000/30);
		}
	}
}
