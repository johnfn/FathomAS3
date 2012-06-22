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

    /* Return the location that this entity will be one timestep in the future, ignoring collisions. */
    public function nextLoc():MovingEntity {
      return new MovingEntity(x + vx, y + vy, gfxWidth, gfxHeight, color, false);
    }
  }
}
