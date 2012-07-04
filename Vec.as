package {
  import flash.display.Sprite;
  import flash.utils.getQualifiedClassName;

  /** Vector class (2d line indicating movement). */

  // TODO: Although usually used like a Vector, it is in some cases
  // used more like a Pair, so maybe that would be a better name.
  public class Vec implements IPositionable {
    internal var _x:Number;
    internal var _y:Number;

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

    public function clone():Vec {
      return new Vec(_x, _y);
    }

    public function map(f:Function):Vec {
      x = f(x);
      y = f(y);

      return this;
    }

    public function add(v:IPositionable):Vec {
      x += v.x;
      y += v.y;

      return this;
    }

    public function subtract(v:*):Vec {
      if (v is IPositionable) {
        var vec:Vec = v as Vec;

        x -= v.x;
        y -= v.y;
      } else if (getQualifiedClassName(v) == "int") {
        var val:int = v as int;

        x -= val;
        y -= val;
      }

      return this;
    }

    // Takes either a Vector or an int (treated as a Vector(int, int))
    public function multiply(n:*):Vec {
      if (getQualifiedClassName(n) == "int") {
        var val:Number = n as Number;

        x *= n;
        y *= n;
      } else if (getQualifiedClassName(n) == "Vec") {
        var vec:Vec = n as Vec;

        x *= n.x;
        y *= n.y;
      } else {
        throw new Error("Unsupported type for Vec#multiply.");
      }

      return this;
    }

    public function divide(n:*):Vec {
      if (getQualifiedClassName(n) == "int") {
        var val:Number = n as Number;

        x /= n;
        y /= n;
      } else if (getQualifiedClassName(n) == "Vec") {
        var vec:Vec = n as Vec;

        x /= n.x;
        y /= n.y;
      } else {
        throw new Error("Unsupported type for Vec#multiply.");
      }

      return this;
    }

    public function normalize():Vec {
      var mag:Number = Math.sqrt(x * x + y * y);

      x /= mag;
      y /= mag;

      return this;
    }

    public function nonzero():Boolean {
      return x != 0 || y != 0;
    }

    public function max():Number {
      return x > y ? x : y;
    }

    public function min():Number {
      return x < y ? x : y;
    }
  }
}
