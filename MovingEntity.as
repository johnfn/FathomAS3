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

    public var xColl:EntityList = new EntityList([]);
    public var yColl:EntityList = new EntityList([]);

    public var touchingLeft:Boolean   = false;
    public var touchingRight:Boolean  = false;
    public var touchingTop:Boolean    = false;
    public var touchingBottom:Boolean = false;

    /* List of all entities that this entity collided with in this time step. */
    internal var collisionList:EntityList = new EntityList([]);

    function MovingEntity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, wiggle:int = 2):void {
      super(x, y, width, height, wiggle);
      _isStatic = false;

      on("post-update", Hooks.resolveCollisions());
    }

    public override function update(e:EntityList):void {
      super.update(e);
    }

    public override function toString():String {
      return super.toString() + " with vel: " + vel.toString();
    }

    // TODO. This won't return anything you aren't obstructed by.
    public override function touching(...args):Boolean {
      return xColl.any.apply(this, args) || yColl.any.apply(this, args);
    }

    public override function set(v:IPositionable):Vec {
      Hooks.clearCollisions(this);
      super.set(v);

      return this;
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
