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

    public static function onLeaveMap(who:Entity, map:Map, callback:Function):Function {
      return function():void {
        if (who.x <= 0 || who.y <= 0 || who.x >= map.width || who.y >= map.height) {
          callback.call(who);
        }
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
        if (Util.entities.any(function(other:Entity):Boolean { return other.collides(that); } )) {
          this.x -= this.vx;
          this.vx = 0;
        }

        this.y += this.vy;
        if (Util.entities.any(function(other:Entity):Boolean { return other.collides(that); } )) {
          this.y -= this.vy;
          this.vy = 0;
        }
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
