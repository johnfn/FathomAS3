package {
  import flash.display.MovieClip;
  import flash.geom.Point;
  import flash.geom.Rectangle;

  import Hooks;
  import Util;

  public class MovingEntity extends Entity {
    public var vx:int = 0;
    public var vy:int = 0;

    function MovingEntity(x:Number = 0, y:Number = 0, gfxWidth:Number = 20, gfxHeight:Number = -1, color:Number = 0xFF0000, visible:Boolean = true):void {
      super(x, y, gfxWidth, gfxHeight, color, visible);
    }

    public override function collides(other:Entity) {
      if (visible) return false;

      return (!eq(other)) && hitTestObject(other);
    }

    public override function collidesPt(point:Point):Boolean {
      if (visible) return false;

      return hitTestPoint(point.x, point.y);
    }

    /* Return the location that this entity will be one timestep in the future, ignoring collisions. */
    public function nextLoc():MovingEntity {
      //TODO: Should really REALLY just make a Rectangle here.
      return new MovingEntity(x + vx, y + vy, gfxWidth, gfxHeight, color, false);
    }
  }
}
