package {
  import flash.display.Sprite;
  import flash.geom.Point;

  public class Hooks {
    public static function move(direction:Point):Function {
      return function():void {
        this.x += direction.x;
        this.y += direction.y;
      }
    }
  }
}
