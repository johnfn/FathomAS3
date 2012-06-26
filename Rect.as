package {
  public class Rect implements IPositionable, IEqual {
    import flash.geom.Point;
    import flash.utils.getQualifiedClassName;

    private var _x:Number;
    private var _y:Number;

    public var width:Number = 0;
    public var height:Number = 0;
    public var right:Number = 0;
    public var bottom:Number = 0;

    public function get x():Number { return _x; }
    public function get y():Number { return _y; }

    function Rect(x:Number, y:Number, width:Number, height:Number = -1) {
      if (height == -1) height = width;

      this._x = x;
      this._y = y;
      this.width = width;
      this.height = height;
      this.right = this.x + this.width;
      this.bottom = this.y + this.height;
    }

    /* Does Rect contain point p? */
    public function containsPt(p:Point):Boolean {
      return x <= p.x && p.x < right && y <= p.y && p.y < bottom;
    }

    public function touchesGround():Boolean {
      var footY:Number = y + this.height;
      var pts:MagicArray = new MagicArray();
      var that:Rect = this;

      for (var footX:Number = x + 2; footX < x + this.width - 2; footX += 2) {
        pts.push(new Point(footX, footY));
      }

      return pts.myMap(function(p:Point):Boolean {
        return Util.entities.exclude(that).any(function(other:Entity):Boolean {
          return other.collidesPt(p);
        });
      }).any();
    }

    /* IPositionable */

    public function setX(n:Number):IPositionable {
      return new Rect(n, _y, width, height);
    }

    public function setY(n:Number):IPositionable {
      return new Rect(_x, n, width, height);
    }

    public function setXY(x:Number, y:Number):IPositionable {
      return new Rect(x, y, width, height);
    }

    public function map(f:Function):IPositionable {
      return new Rect(f(_x), f(_y), width, height);
    }

    public function add(v:IPositionable):IPositionable {
      return new Rect(_x + v.x, _y + v.y, width, height);
    }

    public function subtract(v:IPositionable):IPositionable {
      return new Rect(_x - v.x, _y - v.y, width, height);
    }

    // Takes either a Vector or an int (treated as a Vector(int, int))
    public function multiply(n:*):IPositionable {
      if (getQualifiedClassName(n) == "int") {
        var val:int = n as int;

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

    public function touchingRect(rect:Rect):Boolean {
      return !   (rect.x      > this.x + this.width  ||
         rect.x + rect.width  < this.x               ||
         rect.y               > this.y + this.height ||
         rect.y + rect.height < this.y               );
    }

    /* IEqual */

    private var _uid:int = Util.getUniqueID();

    public function get uid():int { return _uid; }
    public function equals(r:IEqual):Boolean { return uid == r.uid; }
    public function asCloneOf(c:IEqual):IEqual {
      this._uid = c.uid;
      return this;
    }
  }
}
