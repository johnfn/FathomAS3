package {
  public class Rect extends Vec implements IPositionable {
    import flash.geom.Point;
    import flash.utils.getQualifiedClassName;

    public var _width:Number = 0;
    public var _height:Number = 0;
    public var _right:Number = 0;
    public var _bottom:Number = 0;

    function Rect(x:Number, y:Number, width:Number, height:Number = -1) {
      if (height == -1) height = width;

      this._x = x;
      this._y = y;
      this.width = width;
      this.height = height;
      this.right = this.x + this.width;
      this.bottom = this.y + this.height;
    }

    /* Try to be smart about updating coordinates.
     *
     * If you set the width, that changes right also. If you set
     * right, that conversely changes the width. And so forth.
     */

    public override function set x(val:Number):void {
      this._x = val;
      this._right = this._x + this._width;
    }

    public override function set y(val:Number):void {
      this._y = val;
      this._right = this._y + this._height;
    }

    public function set width(val:Number):void {
      this._width = val;
      this._right = this._x + this._width;
    }

    public function get width():Number {
      return this._width;
    }

    public function set height(val:Number):void {
      this._height = val;
      this._bottom = this._y + this._height;
    }

    public function get height():Number {
      return this._height;
    }

    public function set right(val:Number):void {
      this._right = val;
      this._width = this._right - this._x;
    }

    public function get right():Number {
      return this._right;
    }

    public function set bottom(val:Number):void {
      this._bottom = val;
      this._height = this._bottom - this._y;
    }

    public function get bottom():Number {
      return this._bottom;
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

    public override function clone():Vec {
      return new Rect(_x, _y, width, height);
    }

    public function touchingRect(rect:Rect):Boolean {
      return !   (rect.x      > this.x + this.width  ||
         rect.x + rect.width  < this.x               ||
         rect.y               > this.y + this.height ||
         rect.y + rect.height < this.y               );
    }

    public override function toString():String {
      return "[Rect (" + x + ", " + y + ") w: " + width + " h: " + height + "]";
    }

    public override function equals(v:Vec):Boolean {
      if (Util.className(v) != "Rect") return false;

      var r:Rect = v as Rect;

      return x == r.x && y == r.y && width == r.width && right == r.right;
    }
  }
}
