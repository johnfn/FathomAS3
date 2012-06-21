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

    public static function rpgLike(speed:int):Function {
      return function():void {
        var v:Vec = Util.movementVector().multiply(speed);

        trace(v);

        this.vx += v.x;
        this.vy += v.y;

        this.x += this.vx;
        this.y += this.vy;

        trace(this.x, this.y);
      }
    }

    public static function resolveCollisions():Function {
      return function():void {
        var that:* = this;

        if (Util.entities.any(function(other:Entity):Boolean { return other.collides(that); } )) {
          this.x -= this.vx;
          this.vx = 0;
        }

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
