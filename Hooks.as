package {
  import flash.display.Sprite;
  import flash.geom.Point;

  public class Hooks {
    public static function move(direction:Vec):Function {
      return function():void {
        this.pos.add(direction);
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
        if (who.pos.x <= 0 || who.pos.y <= 0 || who.pos.x >= map.width || who.pos.y >= map.height) {
          callback.call(who);
        }
      }
    }

    public static function loadNewMap(leftScreen:MovingEntity, map:Map):Function {
      return function():void {
        var dir:Vec = leftScreen.pos.divide(map.sizeVector).map(Math.floor);
        leftScreen.pos = leftScreen.pos.subtract(dir.multiply(map.sizeVector)) as Rect;

        map.moveCorner(dir);
      }
    }

    public static function rpgLike(speed:int):Function {
      return function():void {
        var v:Vec = Util.movementVector().multiply(speed);

        this.vel = this.vel.add(v);

        this.pos = this.pos.add(this.vel);
      }
    }

    // The common way to use this would be to emit rgpLike, then this function.
    // You may be wondering why we add on the movement, then subtract, then add again.
    // Seems a bit inefficient. The reason is that this allows us to drop in an emit
    // for collisions with objects that we otherwise couldn't walk through.

    // i.e.

    // emit("pre-update", rpgLike);
    // emit("pre-update", pickupItem);
    // emit("pre-update", resolveCollisions);

    public static function resolveCollisions():Function {
      return function():void {
        var that:* = this;

        // Reset to known good collision state.
        this.pos = this.pos.subtract(this.vel) as Rect;

        // Try both x and y.
        this.pos = this.pos.add(new Vec(this.vel.x, 0));
        if (this.touchesAnything()) {
          this.pos = this.pos.subtract(new Vec(this.vel.x, 0));
          this.vel.setX(0);
        }

        this.pos = this.pos.add(new Vec(0, this.vel.y));
        if (this.touchesAnything()) {
          this.pos = this.pos.subtract(new Vec(0, this.vel.y));
          this.vel.setY(0);
        }
      }
    }

    public static function platformerLike(speed:int, entity:MovingEntity):Function {
      return function():void {
        var movement:Vec = new Vec(Util.movementVector().multiply(speed).x, 5);
        entity.vel = entity.vel.add(movement) as Vec;

        if (Util.keyIsDown(Util.Key.Up)) {
          if (entity.nextLoc().touchesGround()) {
            entity.vel.y -= 150;
          }
        }

        entity.pos = entity.pos.add(entity.vel) as Rect;
      }
    }

    public static function decel(decel:Number = 2):Function {
      var cutoff:int = 0.5;

      return function():void {
        if (Math.abs(this.vel.x) < cutoff) { this.vel.x = 0; }
        if (Math.abs(this.vel.y) < cutoff) { this.vel.y = 0; }

        this.vel = this.vel.divide(decel);
      }
    }
  }
}
