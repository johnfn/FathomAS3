package {
  import flash.display.Sprite;

  /** Vector class (2d line indicating movement). */
  public class Vec implements IPositionable {
    private var _x:int;
    private var _y:int;

    function Vec(x:int = 0, y:int = 0) {
      this.x = x;
      this.y = y;
    }

    public function get x():int { return _x; }
    public function set x(val:int):void { this._x = val; }

    public function get y():int { return _y; }
    public function set y(val:int):void { this._y = val; }

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

    public function add(v:IPositionable):IPositionable {
      return new Vec(x + v.x, y + v.y);
    }

    public function subtract(v:IPositionable):IPositionable {
      return new Vec(x - v.x, y - v.y);
    }

    public function multiply(n:int):IPositionable {
      return new Vec(x * n, y * n);
    }

    public function divide(n:int):IPositionable {
      return new Vec(x / n, y / n);
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
