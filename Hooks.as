package {
  import flash.display.Sprite;
  import flash.geom.Point;

  public class Hooks {
    public static function move(direction:Point):Function {
      return function():void {
        this.x += direction.x;
        this.y += direction.y;
      }
    }

    public static function keyPressed(key:Number, callback:Function):Function {
      return function():void {
        if (Util.keyIsDown(key)) {
          callback();
        }
      }
    }

    public static function keyReleased(key:Number, callback:Function):Function {
      return function():void {
        if (Util.keyRecentlyReleased(key)) {
          callback();
        }
      }
    }

    public static function onLeaveMap(who:MovingEntity, map:Map, callback:Function):Function {
      return function():void {
        if (who.x <= 0 || who.y <= 0 || who.x >= map.width || who.y >= map.height) {
          callback.call(who);
        }
      }
    }

    public static function loadNewMap(leftScreen:MovingEntity, map:Map):Function {
      return function():void {
        var dx:int = Math.floor(leftScreen.x / map.width);
        var dy:int = Math.floor(leftScreen.y / map.height);

        leftScreen.x -= dx * map.width;
        leftScreen.y -= dy * map.height;

        map.moveCorner(new Vec(dx, dy));
      }
    }

    public static function rpgLike(speed:int):Function {
      return function():void {
        var v:Vec = Util.movementVector().multiply(speed);

        this.vx += v.x;
        this.vy += v.y;

        this.x += this.vx;
        this.y += this.vy;
      }
    }

    public static function resolveCollisions():Function {
      return function():void {
        var that:* = this;

        // Reset to known good collision state.
        this.x -= this.vx;
        this.y -= this.vy;

        // Try both x and y.
        this.x += this.vx;
        if (this.touchesAnything()) {
          this.x -= this.vx;
          this.vx = 0;
        }

        this.y += this.vy;
        if (this.touchesAnything()) {
          this.y -= this.vy;
          this.vy = 0;
        }
      }
    }

    public static function platformerLike(speed:int, entity:MovingEntity):Function {
      return function():void {
        entity.vx += Util.movementVector().multiply(speed).x;
        entity.vy += 5;

        if (Util.keyIsDown(Util.Key.Up)) {
          if (entity.nextLoc().touchesGround()) {
            entity.vy -= 50;
          }
        }

        entity.x += entity.vx;
        entity.y += entity.vy;
      }
    }

    public static function decel(decel:Number = 2):Function {
      var cutoff:int = 0.5;

      return function():void {
        if (Math.abs(this.vx) < cutoff) { this.vx = 0; }
        if (Math.abs(this.vy) < cutoff) { this.vy = 0; }

        this.vx /= decel;
        this.vy /= decel;
      }
    }
  }
}
