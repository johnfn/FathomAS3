package {
	import Util;

	class Color {
		function Color(r:int, g:int, b:int) {
			r = r;
			g = g;
			b = b;
		}

		function toString():String {
			return "#" + r.toString(16).charAt(0)
			           + g.toString(16).charAt(0)
			           + b.toString(16).charAt(0);
		}

		function randomizeRed(low:int=0, high:int=255):Color {
			r = Util.randRange(low, high);
			return this;
		}

		function randomizeGreen(low:int=0, high:int=255):Color {
			g = Util.randRange(low, high);
			return this;
		}

		function randomizeBlue(low:int=0, high:int=255):Color {
			b = Util.randRange(low, high);
			return this;
		}
	}
}
