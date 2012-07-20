package {
  import flash.display.Sprite;
  import flash.geom.Point;
  import flash.utils.getTimer;

  public class Hooks {
    public static function move(direction:Vec):Function {
      return function():void {
        this.add(direction);
      }
    }

    //TODO...
    public static function after(time:int, callback:Function):Function {
      var timeLeft:int = time;

      return function():void {
        if (!timeLeft--) {
          callback();
        }
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

    //TODO: Not a Hook.
    public static function hasLeftMap(who:MovingEntity, map:Map):Boolean {
      return who.x < 0 || who.y < 0 || who.x > map.width - who.width || who.y > map.height - who.width;
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
        var i:int;
        var NUDGE:Number = 0.01;

        if (this.xColl.length == 0 && this.yColl.length == 0) return;

        if (this.touchingRight) {
          var rightest:int = 0;
          for (i = 0; i < this.xColl.length; i++) {
            rightest = Math.max(rightest, this.xColl[i].x - this.width - NUDGE);
          }

          this.x = rightest;
        } else if (this.touchingLeft) {
          var leftist:int = 9999;
          for (i = 0; i < this.xColl.length; i++) {
            leftist = Math.min(leftist, this.xColl[i].x + this.xColl[i].width + NUDGE);
          }

          this.x = leftist;
        }

        if (this.touchingBottom) {
          // Place this on top of the highest item we were touching.
          var highest:int = 9999;
          for (i = 0; i < this.yColl.length; i++) {
            highest = Math.min(highest, this.yColl[i].y - this.height - NUDGE);
          }

          this.y = highest;
        } else if (this.touchingTop) {
          var lowest:int = 0;
          for (i = 0; i < this.yColl.length; i++) {
            lowest = Math.max(lowest, this.yColl[i].y + this.yColl[i].height + NUDGE);
          }

          this.y = lowest;
        }
      }
    }

    public static function clearCollisions(m:MovingEntity):void {
      m.xColl = new EntityList([]);
      m.yColl = new EntityList([]);
    }

    public static function removeUnnecessaryVelocity():Function {
      return function():void {
        if (this.touchingRight) this.vel.x = Math.min(this.vel.x, 0);
        if (this.touchingLeft) this.vel.x = Math.max(this.vel.x, 0);

        if (this.touchingTop) this.vel.y = Math.max(this.vel.y, 0);
        if (this.touchingBottom) this.vel.y = Math.min(this.vel.y, 0);
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
        var normalizedVel:Vec = entity.vel.clone().normalize();
        var steps:int = entity.vel.clone().divide(normalizedVel).NaNsTo(0).max();
        var that:* = entity;

        // Find which sides we're touching.

        entity.touchingLeft   = false;
        entity.touchingRight  = false;
        entity.touchingTop    = false;
        entity.touchingBottom = false;

        entity.x += entity.vel.x;
        entity.xColl = entity.currentlyTouching();
        if (entity.xColl.length > 0) {
          if (entity.vel.x < 0) entity.touchingLeft = true;
          if (entity.vel.x > 0) entity.touchingRight = true;
        }
        entity.x -= entity.vel.x;

        entity.y += entity.vel.y;
        entity.yColl = entity.currentlyTouching();
        if (entity.yColl.length > 0) {
          if (entity.vel.y < 0) entity.touchingTop = true;
          if (entity.vel.y > 0) entity.touchingBottom = true;
        }
        entity.y -= entity.vel.y;

        entity.add(entity.vel);

        if (entity.currentlyTouching().length > 0 && (entity.yColl.length == 0 && entity.xColl.length == 0)) {
          // We are currently on a corner. Our original plan of attack won't work unless we favor one direction over the other. We choose to favor the x direction.
          entity.y -= entity.vel.y;
          entity.vel.y = 0;
        }
      }
    }

    public static function fpsCounter():Function {
      // With thanks to http://kaioa.com/node/83

      var last:uint = getTimer();
      var ticks:uint = 0;
      var text:String = "--.- FPS";

      return (function():String {
        var now:uint = getTimer();
        var delta:uint = now - last;

        ticks++;
        if (delta >= 1000) {
          var fps:Number = ticks / delta * 1000;
          text = fps.toFixed(1) + " FPS";
          ticks = 0;
          last = now;
        }
        return text;
      });
    }

    public static function flicker(duration:int = 50, callback:Function=null):Function {
      var counter:int = 0;

      var fn:Function = function():void {
        counter++;

        this.visible = (Math.floor(counter / 3) % 2 == 0)

        if (counter > duration) {
          this.visible = true;
          this.off("pre-update", fn);
          if (callback != null) callback();
        }
      }

      return fn;
    }

    public static function decel(decel:Number = 2):Function {
      var cutoff:Number = 0.4;
      var lowCutoff:Number = 20;

      var truncate:Function = function(val:Number):Number {
        if (Math.abs(val) < cutoff) {
          return 0;
        }
        if (Math.abs(val) > lowCutoff) return Util.sign(val) * lowCutoff; //TODO: This hides a problem where falling velocity gets too large.
        return val;
      }

      return function():void {
        this.vel.map(truncate)//.addAwayFromZero(0.6, 0.0);
      }
    }
  }
}
