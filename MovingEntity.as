package {
  import flash.display.MovieClip;
  import flash.geom.Point;
  import flash.geom.Rectangle;

  import Hooks;
  import Util;

  public class MovingEntity extends Entity {
    /* Velocity of the MovingEntity. */
    public var vel:Vec = new Vec(0, 0);
    public var resetVec:Vec = new Vec(0, 0);

    public var xColl:EntityList;
    public var yColl:EntityList;

    public var touchingLeft:Boolean   = false;
    public var touchingRight:Boolean  = false;
    public var touchingTop:Boolean    = false;
    public var touchingBottom:Boolean = false;

    /* List of all entities that this entity collided with in this time step. */
    internal var collisionList:EntityList = new EntityList([]);

    function MovingEntity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, color:Number = 0xFF0000, visible:Boolean = true):void {
      super(x, y, width, height, color, visible);

      on("post-update", Hooks.resolveCollisions());
    }

    public override function update(e:EntityList):void {
      super.update(e);
    }

    /*
    TODO: Think this through.
    public override function collides(other:Entity):Boolean {
      if (other is MovingEntity && !other.equals(this)) {
        return super.collides(other);
      }

      return collisionList.indexOf(other) != -1;
    }
    */
  }
}
