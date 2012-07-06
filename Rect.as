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

    /* Is r contained entirely within this Rect? */
    public function containsRect(r:Rect):Boolean {
      return x <= r.x      && r.x      < right &&
             x <= r.right  && r.right  < right &&
             y <= r.bottom && r.bottom < right &&
             y <= r.y      && r.y      < right;
    }

    public function makeBigger(size:int):Rect {
      return new Rect(_x - size, _y - size, width + size * 2, height + size * 2);
    }

    // Arguments:
    // (-1, 0) left hand side
    // (1, 0) right hand side,
    // (0, -1) top
    // (0, 1) bottom.

    //TODO: The arguments here don't make sense to anyone but me.
    public function touchesSide(sideX:int, sideY:int):Boolean {
      // This is equivalent to sideX ^ sideY, but flash doesn't support boolean xor.
      Util.assert(((sideX == 0) || (sideY == 0)) && !((sideX == 0) && (sideY == 0)));
      Util.assert(width == height);

      //TODO: Assumption that width=height.

      var constant:Number = y + (sideX == -1 || sideY == -1 ? this.height : this.height + this.width);
      var pts:MagicArray = new MagicArray();
      var that:Rect = this;

      for (var vary:Number = 0; vary < this.width; vary += 2) {
        if (sideY != 0) {
          pts.push(new Point(x + vary, constant));
        } else {
          pts.push(new Point(constant, y + vary));
        }
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
