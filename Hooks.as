package {
  import flash.display.Sprite;
  import flash.geom.Point;

  public class Hooks {
    public static function move(direction:Vec):Function {
      return function():void {
        this.add(direction);
      }
    }

    public static function patrol(speed:int, obj:MovingEntity):Function {
      return function():void {
        obj.x += 1;
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
       */
    public static function platformerLike(movement:Vec, entity:MovingEntity):void {
      entity.resetVec = new Vec(0, 0);
      entity.vel.add(movement);

      var normalizedVel:Vec = entity.vel.clone().normalize();
      var coll:EntityList = entity.currentlyTouching();
      var steps:int = entity.vel.clone().divide(normalizedVel).max();

      // Check for collisions in both x and y directions.

      entity.iterate_xy_as_$(function():void {
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

      // Move onto the thing we just collided with.

      entity.y -= entity.resetVec.y;

      entity.touchingGround = entity.vel.y > 0 && entity.currentlyTouching().length;

      entity.x -= entity.resetVec.x;
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
