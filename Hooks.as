package {
  import flash.display.Sprite;
  import flash.geom.Point;

  public class Hooks {
    public static function move(direction:Vec):Function {
      return function():void {
        this.add(direction);
      }
    }

    // Every tick the key is down.
    public static function keyDown(key:Number, callback:Function):Function {
      return function():void {
        if (Util.keyIsDown(key)) {
          callback();
        }
      }
    }

    // Exactly at the start of a keypress.
    public static function keyRecentlyDown(key:Number, callback:Function):Function {
      return function():void {
        if (Util.keyRecentlyDown(key)) {
          callback();
        }
      }
    }

    //TODO...
    public static function entityDestroyed(e:Entity, callback:Function):Function {
      var sentCallback:Boolean = false;

      return function():void {
        if (!sentCallback) {
          callback();
          sentCallback = true;
        }
      }
    }

    public static function keyRecentlyUp(key:Number, callback:Function):Function {
      return function():void {
        if (Util.keyRecentlyUp(key)) {
          callback();
        }
      }
    }

    //TODO: onxxxx methods could be moved into an Events.as file.
    public static function onLeaveMap(who:MovingEntity, map:Map, callback:Function):void {
      if (who.x < 0 || who.y < 0 || who.x > map.width - who.width || who.y > map.height - who.width) {
        callback.call(who);
      }
    }

    public static function loadNewMap(leftScreen:MovingEntity, map:Map):Function {
      //TODO: This code is pretty obscure.
      //TODO: This will only work if leftScreen.width is less than the tileSize.
      return function():void {
        Util.assert(leftScreen.width < map.getTileSize());

        var smallerSize:Vec = map.sizeVector.clone().subtract(leftScreen.width);
        var dir:Vec = leftScreen.clone().divide(smallerSize).map(Math.floor);
        var toOtherSide:Vec = dir.clone().multiply(smallerSize);

        leftScreen.iterate_xy_as_$(function():void {
          if (toOtherSide.$ > 0) leftScreen.$ = 1;
          if (toOtherSide.$ < 0) leftScreen.$ = map.sizeVector.$ - map.getTileSize() + 1;
        });

        map.moveCorner(dir.multiply(map.sizeVector));
      }
    }

    public static function rpgLike(speed:int):Function {
      return function():void {
        this.vel.add(Util.movementVector().multiply(speed));
        this.add(this.vel);
      }
    }

    public static function resolveCollisions():Function {
      return function():void {
        this.add(this.resetVec);
      }
    }

    /* In the event of a collision, this function will leave you stuck
       in whatever you collided into. You should call resolveCollisions()
       in order to fix this.

       The reason that we do this is that it allows us to order our emits so that
       we have an explicit window where we can perform collision checks.

       TODO: I think that said window should just be the update() function.
       TODO: platformerLike takes vel as an implicit argument.
       I should think about whether I like that.
       */
    public static function platformerLike(entity:MovingEntity):Function {
      return function():void {
        if (entity.vel.magnitude() == 0) return;

        entity.resetVec = new Vec(0, 0);

        var normalizedVel:Vec = entity.vel.clone().normalize();
        var steps:int = entity.vel.clone().divide(normalizedVel).NaNsTo(0).max();

        // Check for collisions in both x and y directions.

        entity.iterate_xy_as_$(function():void {
          var coll:EntityList;

          for (var i:int = 0; i < steps; i++) {
            entity.$ += normalizedVel.$;
            coll = entity.currentlyTouching();
            if (coll.length > 0) {
              entity.collisionList = coll;
              entity.resetVec.$ = -normalizedVel.$;
              entity.$ -= normalizedVel.$;
              break;
            }
          }
        });

        // After that finished, we aren't touching anything.

        // Find which sides we're touching.

        entity.touchingLeft   = false;
        entity.touchingRight  = false;
        entity.touchingTop    = false;
        entity.touchingBottom = false;

        entity.x -= entity.resetVec.x;
        if (entity.currentlyTouching().length > 0) {
          if (entity.vel.x < 0) entity.touchingLeft = true;
          if (entity.vel.x > 0) entity.touchingRight = true;
        }
        entity.x += entity.resetVec.x;

        entity.y -= entity.resetVec.y;
        if (entity.currentlyTouching().length > 0) {
          if (entity.vel.y < 0) entity.touchingTop = true;
          if (entity.vel.y > 0) entity.touchingBottom = true;
        }
        entity.y += entity.resetVec.y;

        // Move onto the thing we just collided with.

        entity.subtract(entity.resetVec);
      }
    }

    public static function flicker(duration:int = 50):Function {
      var counter:int = 0;

      var fn:Function = function():void {
        counter++;

        this.visible = (Math.floor(counter / 3) % 2 == 0)

        if (counter > duration) {
          this.visible = true;
          this.off("pre-update", fn);
        }
      }

      return fn;
    }

    public static function decel(decel:Number = 2):Function {
      var cutoff:int = 0.5;

      var truncate:Function = function(val:int):int {
        return Math.abs(val) < cutoff ? 0 : val;
      }

      return function():void {
        this.vel.map(truncate).divide(decel);
      }
    }
  }
}
