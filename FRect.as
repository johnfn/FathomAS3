package {
  // Extending FPoint admittedly seems a bit strange, but you'll quickly
  // see that it has many advantages. It helps to think of the FRect as a
  // point (the top left point) with a width and height.
  public class FRect extends FPoint {
    function FRect(x:int, y:int, width:int, height:int = -1) {
      if (height == -1) height = width;

      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
      this.right = this.x + this.width;
      this.bottom = this.y + this.height;
    }

    public function touchingRect(rect:Rect) {
      return not (rect.x      > this.x + this.width  ||
         rect.x + rect.width  < this.x               ||
         rect.y               > this.y + this.height ||
         rect.y + rect.height < this.y               );
    }

    public function touchingPoint(p:Point) {
      return this.x <= point.x && point.x <= this.right && this.y <= point.y && point.y <= this.bottom;
    }
  }
}
