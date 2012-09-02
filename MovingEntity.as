package {
  import flash.display.MovieClip;
  import flash.geom.Point;
  import flash.geom.Rectangle;

  import Hooks;
  import Util;

  public class MovingEntity extends Entity {
    /* Velocity of the MovingEntity. */
    public var vel:Vec = new Vec(0, 0);
    public var oldVel:Vec = new Vec(0, 0);
    public var reset:Boolean = false;

    public var xColl:EntityList = new EntityList([]);
    public var yColl:EntityList = new EntityList([]);

    public var flagsSet:Boolean       = false;

    public var touchingLeft:Boolean   = false;
    public var touchingRight:Boolean  = false;
    public var touchingTop:Boolean    = false;
    public var touchingBottom:Boolean = false;

    /* List of all entities that this entity collided with in this time step. */
    internal var collisionList:EntityList = new EntityList([]);

    function MovingEntity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1):void {
      super(x, y, width, height);
      _isStatic = false;
    }

    public override function update(e:EntityList):void {
      this.oldVel = this.vel.clone();
      this.reset = false;

      super.update(e);
    }

    public override function toString():String {
      return super.toString() + " with vel: " + vel.toString();
    }

    // TODO. This won't return anything you aren't obstructed by.
    public override function touching(...args):Boolean {
      return xColl.any.apply(this, args) || yColl.any.apply(this, args);
    }

    public override function currentlyTouching(...args):EntityList {
      return xColl.get.apply(this, args).join(yColl.get.apply(this, args));
    }
  }
}
