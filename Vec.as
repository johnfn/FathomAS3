package {
  import flash.display.Sprite;
  import flash.utils.getQualifiedClassName;

  /** Vector class (2d line indicating movement). */
  public class Vec implements IPositionable {
    private var _x:Number;
    private var _y:Number;

    function Vec(x:Number = 0, y:Number = 0) {
      this.x = x;
      this.y = y;
    }

    public function get x():Number { return _x; }
    public function set x(val:Number):void { this._x = val; }

    public function get y():Number { return _y; }
    public function set y(val:Number):void { this._y = val; }

    public function eq(v:Vec):Boolean {
      return x == v.x && y == v.y;
    }

    public function toString():String {
    	return "Vec[" + this.x + ", " + this.y + "]";
    }

    public function randomize():Vec {
      var r:Number = Util.randRange(0, 4);

      if (r == 0) { return new Vec( 0,  1); }
      if (r == 1) { return new Vec( 0, -1); }
      if (r == 2) { return new Vec( 1,  0); }
      if (r == 3) { return new Vec(-1,  0); }

      return new Vec(0, 0); //This line never executes. It's just to satisfy type checker.
    }

    public function map(f:Function):IPositionable {
      return new Vec(f(_x), f(_y));
    }

    /* IPositionable */

    public function setXY(x:Number, y:Number):IPositionable {
      return new Vec(x, y);
    }

    public function setX(n:Number):IPositionable {
      return new Vec(n, _y);
    }

    public function setY(n:Number):IPositionable {
      return new Vec(_x, n);
    }

    public function add(v:IPositionable):IPositionable {
      return new Vec(x + v.x, y + v.y);
    }

    public function subtract(v:IPositionable):IPositionable {
      return new Vec(x - v.x, y - v.y);
    }

    // Takes either a Vector or an int (treated as a Vector(int, int))
    public function multiply(n:*):IPositionable {
      if (getQualifiedClassName(n) == "int") {
        var val:Number = n as Number;

        return new Vec(_x * n, _y * n);
      } else if (getQualifiedClassName(n) == "Vec") {
        var vec:Vec = n as Vec;

        return new Vec(_x * vec.x, _y * vec.y);
      } else {
        throw new Error("Unsupported type for Vec#multiply.");
      }
    }

    public function divide(n:*):IPositionable {
      if (getQualifiedClassName(n) == "int") {
        var val:Number = n as Number;

        return new Vec(_x / n, _y / n);
      } else if (getQualifiedClassName(n) == "Vec") {
        var vec:Vec = n as Vec;

        return new Vec(_x / vec.x, _y / vec.y);
      } else {
        throw new Error("Unsupported type for Vec#multiply.");
      }
    }

    public function normalize():Vec {
      var mag:Number = Math.sqrt(x * x + y * y);

      return new Vec(x / mag, y / mag);
    }

    public function nonzero():Boolean {
      return x != 0 || y != 0;
    }
  }
}
