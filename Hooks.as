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
        var dir:Vec = leftScreen.pos.clone();
        dir.divide(map.sizeVector);
        dir.map(Math.floor);
        dir.multiply(map.sizeVector);

        leftScreen.pos.subtract(dir);

        map.moveCorner(dir);
      }
    }

    public static function rpgLike(speed:int):Function {
      return function():void {
        var v:Vec = Util.movementVector().clone();
        v.multiply(speed);

        this.vel.add(v);

        this.pos.add(this.vel);
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

    //TODO: In the case of moving off the side of a map, collision detection gets messy.
    public static function resolveCollisions():Function {
      return function():void {
        var that:* = this;

        // Reset to known good collision state.
        this.pos.subtract(this.vel);

        // Try both x and y.
        this.pos.x += this.vel.x;
        if (this.touchesAnything().length) {
          this.pos.x -= this.vel.x;
          this.vel.x = 0;
        }

        this.pos.y += this.vel.y;
        if (this.touchesAnything().length) {
          this.pos.y -= this.vel.y;
          this.vel.y = 0;
        }
      }
    }

    public static function platformerLike(speed:int, entity:MovingEntity):Function {
      return function():void {
        var movement:Vec = new Vec(Util.movementVector().x * speed, 5);
        entity.vel.add(movement);

        if (Util.keyIsDown(Util.Key.Up)) {
          if (entity.nextLoc().touchesGround()) {
            entity.vel.y -= 150;
          }
        }

        var normalizedVel:Vec = entity.vel.clone();
        normalizedVel.normalize();

        var coll:EntityList = entity.touchesAnything();
        var steps:int = Math.max(entity.vel.x / normalizedVel.x, entity.vel.y / normalizedVel.y);

        for (var i:int = 0; i < steps; i++) {
          entity.pos.x += normalizedVel.x;
          coll = entity.touchesAnything();
          if (coll.length > 0) {
            entity.collisionList = new EntityList([]);
            entity.pos.x -= normalizedVel.x;
            break;
          }
        }

        for (var i:int = 0; i < steps; i++) {
          entity.pos.y += normalizedVel.y;
          coll = entity.touchesAnything();
          if (coll.length > 0) {
            entity.collisionList = new EntityList([]);
            entity.pos.y -= normalizedVel.y;
            break;
          }
        }
      }
    }

    public static function decel(decel:Number = 2):Function {
      var cutoff:int = 0.5;

      return function():void {
        if (Math.abs(this.vel.x) < cutoff) { this.vel.x = 0; }
        if (Math.abs(this.vel.y) < cutoff) { this.vel.y = 0; }

        this.vel.divide(decel);
      }
    }
  }
}
