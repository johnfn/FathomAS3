package {
  import flash.display.Sprite;

  /** Immutable Vector class (2d line indicating movement). */
  public class Vec {
    public var x:int;
    public var y:int;

    function Vec(x:int = 0, y:int = 0) {
      this.x = x;
      this.y = y;
    }

    public function eq(v:Vec):Boolean {
      return x == v.x && y == v.y;
    }

    public function toString():String {
    	return "Vec[" + this.x + ", " + this.y + "]";
    }

    public function randomize():Vec {
      var r:int = Util.randRange(0, 4);

      if (r == 0) { return new Vec( 0,  1); }
      if (r == 1) { return new Vec( 0, -1); }
      if (r == 2) { return new Vec( 1,  0); }
      if (r == 3) { return new Vec(-1,  0); }

      return new Vec(0, 0); //This line never executes. It's just to satisfy type checker.
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
      return x != 0 || y != 0;
    }
  }
}
