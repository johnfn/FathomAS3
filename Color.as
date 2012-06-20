package {
	import Util;

	public class Color {
    public var r:int;
    public var g:int;
    public var b:int;

		function Color(r:int = 0, g:int = 0, b:int = 0) {
			r = r;
			g = g;
			b = b;
		}

		public function toString():String {
			return "#" + r.toString(16).charAt(0)
			           + g.toString(16).charAt(0)
			           + b.toString(16).charAt(0);
		}

    public function readInt(n:int):Color {
      g = n % 255;
      n /= 255;
      b = n % 255;
      n /= 255;
      r = n;

      return this;
    }

		public function read(s:String):Color {
			s = s.substring(1);

			r = parseInt(s.substring(0, 2), 16);
			g = parseInt(s.substring(2, 4), 16);
			b = parseInt(s.substring(4, 6), 16);

      return this;
		}

    public function toInt():uint {
      return parseInt(toString(), 16);
    }

		public function randomizeRed(low:int = 0, high:int = 255):Color {
			r = Util.randRange(low, high);
			return this;
		}

		public function randomizeGreen(low:int = 0, high:int = 255):Color {
			g = Util.randRange(low, high);
			return this;
		}

		public function randomizeBlue(low:int = 0, high:int = 255):Color {
			b = Util.randRange(low, high);
			return this;
		}
	}
}
