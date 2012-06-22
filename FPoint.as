package {

  /* FPoint is similar to the AS3 Point class, except immutable and with more
     useful methods. */

  public class FPoint {
    public var x:int;
    public var y:int;

    function FPoint(x:int = 0, y:int = 0) {
      this.x = x;
      this.y = y;
    }

    public function eq(p:Point) {
      return p.x == this.x && p.y == this.y;
    }

    public function toRect(width:int, height:int = -1) {
      if (height == -1) height = width;

      return new FRect(this.x, this.y, width, height);
    }

    public function close(p:Point, threshold:int = 1) {
      return Util.epsilonEq(this.x, p.x, threshold) &&
             Util.epsilonEq(this.y, p.y, threshold);
    }

    public function add(v:Vec) {
      this.x += v.x;
      this.y += v.y;
    }

    public function subtract(p:Point) {
      return new Vector(this.x - p.x, this.y - p.y);
    }
  }
}
