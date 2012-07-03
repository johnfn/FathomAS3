package {
  import flash.display.Sprite;
  import flash.utils.getQualifiedClassName;

  /** Vector class (2d line indicating movement). */
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

    public function map(f:Function):void {
      x = f(x);
      y = f(y);
    }

    public function add(v:IPositionable):void {
      x += v.x;
      y += v.y;
    }

    public function subtract(v:IPositionable):void {
      x -= v.x;
      y -= v.y;
    }

    // Takes either a Vector or an int (treated as a Vector(int, int))
    public function multiply(n:*):void {
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
    }

    public function divide(n:*):void {
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
    }

    public function normalize():void {
      var mag:Number = Math.sqrt(x * x + y * y);

      x /= mag;
      y /= mag;
    }

    public function nonzero():Boolean {
      return x != 0 || y != 0;
    }
  }
}
