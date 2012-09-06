package {
  public class Fathom {
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.display.MovieClip;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.utils.Dictionary;

    private static var gameloopID:int;
    private static var FPS:int = 0;
    private static var fpsFn:Function;
    public static var _camera:Camera; //TODO

    private static var _currentMode:int = 0;

    public static function get camera():Camera { return _camera; }

    public static var mapRef:Map;
    public static var fpsTxt:Text;
    public static var entities:EntitySet = new EntitySet([]);
    public static var container:Entity;
    public static var initialized:Boolean = false;
    public static var stage:Stage;

    public static var modes:Array = [Fathom._currentMode];

    private static var _paused:Boolean = false;

    public static var MCPool:Object = {};

    public function Fathom() {
      throw new Error("You can't initialize a Fathom object. Call the static methods on Fathom instead.")
    }

    public static function get paused():Boolean { return _paused; }

    public static function get scaleX():Number {
      return container.scaleX;
    }

    public static function get scaleY():Number {
      return container.scaleY;
    }

    public static function get currentMode():int {
      return modes[modes.length - 1]
    }

    // TODO this stuff should go in Mode.as
    public static function pushMode(mode:int):void {
      modes.push(mode);
    }

    public static function popMode():void {
      modes.pop();
    }

    public static function replaceMode(mode:int):void {
      modes[modes.length - 1] = mode;
    }

    public static function set showingFPS(b:Boolean):void {
      fpsTxt.visible = b;
    }

    //TODO: Eventually main class should extend this or something...
    public static function initialize(stage:Stage, FPS:int = 30):void {
      // Inside of the Entity constructor, we assert Fathom.initialized, because all
      // MCs must be added to the container MC.

      Fathom.stage = stage;
      Fathom.initialized = true;

      Fathom.FPS = FPS;
      Fathom.container = new Entity();
      Fathom.stage.addChild(Fathom.container);

      fpsFn = Hooks.fpsCounter();
      fpsTxt = new Text(200, 20);

      Util._initializeKeyInput(container);
    }

    public static function start():void {
      container.addEventListener(Event.ENTER_FRAME, update);
    }

    /* This stops everything. The only conceivable use would be
       possibly for some sort of end game situation. */
    public static function stop():void {
      container.removeEventListener(Event.ENTER_FRAME, update);
    }

    // TODO: These should be static functions on MovingEntity.

    // A fast way to find collisions is to subdivide the map into a grid and
    // see if any individual square of the grid contains more than one item in
    // it.
    private static function moveEverything():void {
      var list:EntitySet = movingEntities();
      var grid:SpatialHash = new SpatialHash(Fathom.entities.get("!nonblocking"));

      // Move every non-static entity.
      for each (var e:MovingEntity in list) {
        var xResolved:int, yResolved:int;

        e.vel.x = Math.floor(e.vel.x);
        e.vel.y = Math.floor(e.vel.y);

        e.x = Math.floor(e.x);
        e.y = Math.floor(e.y);

        e.xColl = new EntitySet();
        e.yColl = new EntitySet();

        // Resolve 1 px in the x-direction at a time...
        for (xResolved = 0; xResolved < Math.abs(e.vel.x) + 1; xResolved++) {

          // Attempt to resolve as much of dy as possible on every tick.
          for (var k:int = yResolved; k < Math.abs(e.vel.y); k++) {
            e.y += Util.sign(e.vel.y);
            if (grid.collides(e)) {
              e.yColl.extend(grid.getColliders(e));

              e.y -= Util.sign(e.vel.y);

              break;
            } else {
              yResolved++;
            }
          }

          e.x += Util.sign(e.vel.x);
          if (grid.collides(e)) {
            e.xColl.extend(grid.getColliders(e));
            e.x -= Util.sign(e.vel.x);
          }
        }

        e.touchingBottom = (e.yColl.length && e.vel.y > 0);
        e.touchingTop    = (e.yColl.length && e.vel.y < 0);

        e.touchingLeft   = (e.xColl.length && e.vel.x < 0);
        e.touchingRight  = (e.xColl.length && e.vel.x > 0);
      }
    }

    private static function movingEntities():EntitySet {
      return Fathom.entities.get(function(e:Entity):Boolean {
        return !e.isStatic;
      });
    }

    private static function update(event:Event):void {
      // We copy the entity list so that it doesn't change while we're
      // iterating through it.
      var list:EntitySet = entities.get();

      // TODO: entities == Fathom.container.children
      fpsTxt.text = fpsFn();

      moveEverything();

      for each (var e:Entity in list) {
        if (!e.modes().contains(currentMode)) continue;

        // This acts as a pseudo garbage-collector. We separate out the
        // destroyed() call from the clearMemory() call because we sometimes
        // want to destroy() an item halfway through this update() call, so the
        // actual destruction would have to wait until the end of the update.
        if (e.destroyed) {
          e.clearMemory();
          continue;
        }

        // Util.assert(e.parent != null);

        e.emit("pre-update");
        e.update(entities);
        e.emit("post-update");
      }

      if (mapRef.modes().contains(currentMode)) {
        mapRef.update();
      }

      camera.update();
      Util.dealWithVariableKeyRepeatRates();
    }
  }
}

