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
    public static var entities:EntityList = new EntityList([]);
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

    private static function getCoords(e:Entity):Array {
      var HACK:int = 0;
      var result:Array = [];
      var GRIDSIZE:int = 25;

      // This is subtle. If our gridsize is 25 and we're trying to hash an
      // entity with width 25 at x location 0, we don't want to put it in two
      // different slots. The width of the entity would have to be greater
      // than 25 for us to do that. Or the x location would have to be > 0.

      var endSlotX:int = (e.x + e.width) / GRIDSIZE;
      if ((e.x + e.width) % GRIDSIZE == 0) endSlotX--;

      var endSlotY:int = (e.y + e.height) / GRIDSIZE;
      if ((e.y + e.height) % GRIDSIZE == 0) endSlotY--;

      for (var slotX:int = (e.x / GRIDSIZE); slotX <= endSlotX; slotX++) {
        for (var slotY:int = (e.y / GRIDSIZE); slotY <= endSlotY; slotY++) {
          if (slotX < 0 || slotX >= mapRef.widthInTiles || slotY < 0 || slotY >= mapRef.heightInTiles) {
            continue;
          }

          result.push(new Vec(slotX, slotY));
        }
      }

      return result;
    }

    // TODO you should be able to flag things as no collision (i.e. particles)
    private static function makeGrid():Array {
      var grid:Array = Util.make2DArrayFn(mapRef.widthInTiles, mapRef.heightInTiles, function():Array { return []; });
      var list:EntityList = entities.get("!nonblocking");
      var HACK:int = 1;

      for (var i:int = 0; i < list.length; i++) {
        var coords:Array = getCoords(list[i]);

        for (var j:int = 0; j < coords.length; j++) {
          grid[coords[j].x][coords[j].y].push(list[i]);
        }
      }

      return grid;
    }

    private static function getColliders(e:Entity, g:Array):Set {
      var result:Set = new Set();
      var coords:Array = getCoords(e);

      for (var i:int = 0; i < coords.length; i++) {
        var arr:Array = g[coords[i].x][coords[i].y];

        for (var j:int = 0; j < arr.length; j++) {
          if (arr[j] == e) continue;

          if (e.touchingRect(arr[j])) {
            result.add(arr[j]);
          }
        }
      }

      return result;
    }

    private static function setColliders(entity:MovingEntity, grid:Array):void {
      var newXColliders:Set;
      var newYColliders:Set;

      entity.x -= entity.vel.x;
      entity.y -= entity.vel.y;

      entity.x += entity.vel.x;
      newXColliders = getColliders(entity, grid);
      if (newXColliders.length > 0) {
        if (entity.vel.x < 0) entity.touchingLeft = true;
        if (entity.vel.x > 0) entity.touchingRight = true;
      }
      entity.x -= entity.vel.x;

      entity.y += entity.vel.y;
      newYColliders = getColliders(entity, grid);
      if (newYColliders.length > 0) {
        if (entity.vel.y < 0) entity.touchingTop = true;
        if (entity.vel.y > 0) entity.touchingBottom = true;
      }

      entity.touchingAnything = entity.touchingLeft || entity.touchingRight ||
                                entity.touchingTop  || entity.touchingBottom;

      entity.y -= entity.vel.y;

      entity.x += entity.vel.x;
      entity.y += entity.vel.y;

      if (getColliders(entity, grid).length > 0 && (newXColliders.length == 0 && newYColliders.length == 0)) {
        // We are currently on a corner. Our original plan of attack
        // won't work unless we favor one direction over the other. We
        // arbitrarily choose to favor the x direction.

        // Literally a corner case! Ha! Ha!

        entity.y -= entity.vel.y;
        entity.vel.y = 0;
      }

      newXColliders.foreach(function(o:Entity):void {
        entity.xColl.add(o);

        if (o.isStatic) return;

        (o as MovingEntity).xColl.add(entity);
      });

      newYColliders.foreach(function(o:Entity):void {
        entity.yColl.add(o);

        if (o.isStatic) return;

        (o as MovingEntity).yColl.add(entity);
      });
    }

    // TODO: These should be static functions on MovingEntity.

    // A fast way to find collisions is to subdivide the map into a grid and
    // see if any individual square of the grid contains more than one item in
    // it.
    private static function moveEverything():void {
      var list:EntityList = entities.get("!nonblocking");
      var i:int = 0;
      var grid:Array = makeGrid();

      // Move every non-static entity.
      for (i = 0; i < list.length; i++) {
        if (list[i].isStatic) continue;

        // TODO these should be private.

        list[i].oldLoc = list[i].vec();

        list[i].x += list[i].vel.x;
        list[i].y += list[i].vel.y;

        list[i].xColl = new Set();
        list[i].yColl = new Set();

        list[i].touchingLeft = false;
        list[i].touchingRight = false;
        list[i].touchingTop = false;
        list[i].touchingBottom = false;
        list[i].touchingAnything = false;

        setColliders(list[i], grid);

        list[i].x -= list[i].vel.x;
        list[i].y -= list[i].vel.y;
      }

      for (i = 0; i < list.length; i++) {
        if (list[i].isStatic) continue;

        var e:MovingEntity = list[i] as MovingEntity;

        if (!e.touchingAnything) {
          e.x += e.vel.x;
          e.y += e.vel.y;
        } else {
          var mag:Vec = e.vel.clone().normalize();
          var times:int = e.vel.clone().divide(mag).NaNsTo(0).max();

          if (e.xColl.length == 0) e.x += e.vel.x;
          if (e.yColl.length == 0) e.y += e.vel.y;

          for (var j:int = 0; j < times; j++) {
            if (e.yColl.length) e.y += mag.y;

            if (getColliders(e, grid).length) {
              if (e.yColl.length) e.y -= mag.y;
              break;
            }
          }

          for (var j:int = 0; j < times; j++) {
            if (e.xColl.length) e.x += mag.x;

            if (getColliders(e, grid).length) {
              if (e.xColl.length) e.x -= mag.x;
              break;
            }
          }
        }
      }
    }

    private static function movingEntities():EntityList {
      var result:EntityList = new EntityList([]);

      for (var i:int = 0; i < Fathom.entities.length; i++) {
        if (Fathom.entities[i].isStatic) continue;

        result.push(Fathom.entities[i]);
      }

      return result;
    }

    private static function update(event:Event):void {
      // We copy the entity list so that it doesn't change while we're
      // iterating through it.
      var list:EntityList = entities.get();

      // TODO: entities == Fathom.container.children
      fpsTxt.text = fpsFn();

      moveEverything();

      for (var i:int = 0; i < list.length; i++) {
        var e:Entity = list[i];

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

