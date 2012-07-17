package {
  import Hooks;
  import Util
  import Entity;

  public class HealthIndicator extends Entity {
    function HealthIndicator(x:Number = 0, y:Number = 0):void {
      super(x, y, 16, 16, 0xAA00AA);
    }

    public override function collides(e:Entity):Boolean {
      return false;
    }
  }
}
