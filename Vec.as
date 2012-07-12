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

    // The magic $ variable.

    private static var $_IS_NEITHER:int = 0;
    private static var $_IS_X:int  = 1;
    private static var $_IS_Y:int  = 2;

    private static var $_current_value:int = $_IS_NEITHER;

    public function get $():Number {
      Util.assert($_current_value != $_IS_NEITHER);

      return $_current_value == $_IS_X ? _x : _y;
    }

    public function set $(val:Number):void {
      Util.assert($_current_value != $_IS_NEITHER);

      if ($_current_value == $_IS_X) {
        x = val;
      } else {
        y = val;
      }
    }

    public function equals(v:Vec):Boolean {
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

    /* The idea behind this rather strange function is that we often
    copy code and only change x to y.

    With iterate_xy_as_$, vectors inside of the function you pass in will have
    a magical property "$", which will be the x of the vector the first time
    the function is called, and y the second time.

    Here's a nice example. Before:

    vec.x += 5;
    vec.x /= 2;
    vec.y += 5;
    vec.y /= 2;

    After:

    vec.iterate_xy_as_$(function() {
      this.$ += 5;
      this.$ /= 2;
    });

    It works on many vectors with no change.

    vec1.x += 5
    vec2.x += 5;
    vec1.y += 5
    vec2.y += 5;

    After:

    vec1.iterate_xy_as_$(function() {
      vec1.$ += 5;
      vec2.$ += 5
    });
    */

    //TODO: Maybe this?
    /*
      vec.iter_as_$(['x', 'y'], function() {
        vec1.$ += 5;
        vec2.$ += 5;
      });
    */
    public function iterate_xy_as_$(f:Function):Vec {
      //This can't be nested.
      Util.assert($_current_value == $_IS_NEITHER);

      $_current_value = $_IS_X;

      f();

      $_current_value = $_IS_Y;

      f();

      $_current_value = $_IS_NEITHER;

      return this;
    }

    public function set(v:IPositionable):Vec {
      x = v.x;
      y = v.y;

      return this;
    }

    public function add(v:IPositionable):Vec {
      x += v.x;
      y += v.y;

      return this;
    }

    public function NaNsTo(val:int):Vec {
      if (isNaN(x)) x = val;
      if (isNaN(y)) y = val;

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
      x /= magnitude();
      y /= magnitude();

      return this;
    }

    public function magnitude():int {
      return Math.sqrt(x * x + y * y);
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

    /* Create a unique key to store in an object. */
    public function asKey():String {
      return x + "," + y;
    }
  }
}
