package {
	import flash.display.Sprite;

	/** Immutable Vector class (2d line indicating movement). */
	public class Vec {
		function Vec(x:int = 0, y:int = 0) {
			x = x;
			y = y;
		}

		public function eq(v:Vec) {
			return x == v.x && y == v.y;
		}

		public function randomize():Vec {
			r = Util.randRange(0, 4);

			if (r == 0) { return new Vec( 0,  1); }
			if (r == 1) { return new Vec( 0, -1); }
			if (r == 2) { return new Vec( 1,  0); }
			if (r == 3) { return new Vec(-1,  0); }
		}

		public function multiply(n:int):Vec {
			return new Vec(x * n, y * n);
		}

		public function divide(n:int):Vec {
			return new Vec(x / n, y / n);
		}

		public function add(v:Vec):Vec {
			return new Vec(x + v.x, y + v.y);
		}

		public function normalize():Vec {
			var mag:int = Math.sqrt(x * x + y * y);

			return new Vec(x / mag, y / mag);
		}

		public function nonzero():Boolean {
			return x != 0 or y != 0;
		}
	}
}