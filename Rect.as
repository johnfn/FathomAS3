package {
  public class Rect extends Vec implements IEqual, IPositionable {
    import flash.geom.Point;
    import flash.utils.getQualifiedClassName;

    public var width:Number = 0;
    public var height:Number = 0;
    public var right:Number = 0;
    public var bottom:Number = 0;

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

    public override function clone():Vec {
      return new Rect(_x, _y, width, height);
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
