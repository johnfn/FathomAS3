package {
  import flash.display.MovieClip;
  import flash.geom.Point;
  import flash.geom.Rectangle;

  import Hooks;
  import Util;

  public class MovingEntity extends Entity {
    /* Velocity of the MovingEntity. */
    public var vel:Vec = new Vec(0, 0);

    /* How far the MovingEntity moved this time step. This
       may be different from vel in the case of a collision. */
    public var actualMovement:Vec = new Vec(0, 0);

    /* List of all entities that this entity collided with in this time step. */
    internal var collisionList:EntityList = new EntityList([]);

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

    public override function collides(other:Entity):Boolean {
      if (other is MovingEntity) {
        return super.collides(other);
      }

      return collisionList.indexOf(other) != -1;
    }
  }
}
