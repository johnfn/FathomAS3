package {
  import flash.display.MovieClip;
  import flash.geom.Point;
  import flash.geom.Rectangle;

  import Hooks;
  import Util;

  public class MovingEntity extends Entity {
    public var vel:Vec = new Vec(0, 0);

    function MovingEntity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, color:Number = 0xFF0000, visible:Boolean = true):void {
      super(x, y, width, height, color, visible);
    }

    public override function die():void { __fathom.entities.remove(this); }

    public override function update(e:EntityList):void {
      super.update(e);
    }

    /* Return the location that this entity will be one timestep in the future, ignoring collisions. */
    public function nextLoc():Rect {
      // we need the asCloneOf() call here so that when we return this
      // we don't end up thinking that the nextLoc is colliding with the previous object.
      return (new Rect(pos.x + vel.x, pos.y + vel.y, width, height)).asCloneOf(this) as Rect;
    }
  }
}
