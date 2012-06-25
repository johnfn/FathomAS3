package {
  public class FRect implements IPositionable, IEqual {
    import flash.geom.Point;
    import flash.utils.getQualifiedClassName;

    public var width:int = 0;
    public var height:int = 0;
    public var right:int = 0;
    public var bottom:int = 0;

    function FRect(x:int, y:int, width:int, height:int = -1) {
      if (height == -1) height = width;

      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
      this.right = this.x + this.width;
      this.bottom = this.y + this.height;
    }

    public function touchesGround():Boolean {
      var footY:int = y + this.height;
      var pts:MagicArray = new MagicArray();
      var that:FRect = this;

      for (var footX:int = x + 2; footX < x + this.width - 2; footX += 2) {
        pts.push(new Point(footX, footY));
      }

      return pts.myMap(function(p:Point):Boolean {
        return Util.entities.exclude(that).any(function(other:Entity):Boolean {
          return other.collidesPt(p);
        });
      }).any();
    }

    /* IEqual */

    private var _uid:int = Util.getUniqueID();

    public function get uid():int { return _uid; }
    public function equals(r:IEqual):Boolean { return uid == r.uid; }

    /* IPositionable */

    private var _x:int;
    private var _y:int;

    public function get x():int { return _x; }
    public function set x(val:int):void { this._x = val; }

    public function get y():int { return _y; }
    public function set y(val:int):void { this._y = val; }


    public function add(v:IPositionable):IPositionable {
      return new FRect(_x + v.x, _y + v.y, width, height);
    }

    public function subtract(v:IPositionable):IPositionable {
      return new FRect(_x - v.x, _y - v.y, width, height);
    }

    public function multiply(n:int):IPositionable {
      return new FRect(_x * n, _y * n, width, height);
    }

    public function divide(n:int):IPositionable {
      return new FRect(_x / n, _y / n, width, height);
    }

    public function touchingRect(rect:FRect):Boolean {
      return !   (rect.x      > this.x + this.width  ||
         rect.x + rect.width  < this.x               ||
         rect.y               > this.y + this.height ||
         rect.y + rect.height < this.y               );
    }

    public function touchingPoint(p:Point):Boolean {
      return this.x <= p.x && p.x <= this.right && this.y <= p.y && p.y <= this.bottom;
    }
  }
}
