package {
	public class Util {
		import flash.utils.*;

		public static var uid:Number = 0;
		public static var entities:Entities = new Entities();

		public static function getUniqueID():Number {
			return ++uid;
		}

    public static function make2DArrayFn(width:int, height:int, fn:Function):Array {
      var result:Array = new Array(width);

      for (var i:int = 0; i < width; i++) {
        result[i] = new Array(height);
        for (var j:int = 0; j < height; j++) {
          result[i][j] = fn(i, j);
        }
      }

      return result;
    }

    public static function foreach2D(a:Array, fn:Function):void {
      for (var i:int = 0; i < a.length; i++) {
        for (var j:int = 0; j < a[0].length; j++) {
          fn(i, j, a[i][j]);
        }
      }
    }

		public static function make2DArray(width:int, height:int, defaultValue:*):Array {
      return make2DArrayFn(width, height, function(x:int, y:int):* { return defaultValue; });
		}

		public static function randRange(low:int, high:int):int {
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
