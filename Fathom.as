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

    // TODO: When this.x + this.width == that.x, that's NOT a collision.
    // It just has to be that way.
    private static function getColliders(e:Entity, g:Array):EntityList {
      var result:Array = [];
      var coords:Array = getCoords(e);

      for (var i:int = 0; i < coords.length; i++) {
        var arr:Array = g[coords[i].x][coords[i].y];

        for (var j:int = 0; j < arr.length; j++) {
          if (arr[j] == e) continue;

          if (e.touchingRect(arr[j])) {
            result.push(arr[j]);
          }
        }
      }

      return new EntityList(result);
    }

    private static function setColliders(entity:MovingEntity, grid:Array):void {
      entity.x -= entity.vel.x;
      entity.y -= entity.vel.y;

      entity.x += entity.vel.x;
      entity.xColl = getColliders(entity, grid);
      if (entity.xColl.length > 0) {
        if (entity.vel.x < 0) entity.touchingLeft = true;
        if (entity.vel.x > 0) entity.touchingRight = true;
      }
      entity.x -= entity.vel.x;

      entity.y += entity.vel.y;
      entity.yColl = getColliders(entity, grid);
      if (entity.yColl.length > 0) {
        if (entity.vel.y < 0) entity.touchingTop = true;
        if (entity.vel.y > 0) entity.touchingBottom = true;
      }
      entity.y -= entity.vel.y;

      entity.x += entity.vel.x;
      entity.y += entity.vel.y;

      if (getColliders(entity, grid).length > 0 && (entity.yColl.length == 0 && entity.xColl.length == 0)) {
        // We are currently on a corner. Our original plan of attack
        // won't work unless we favor one direction over the other. We
        // arbitrarily choose to favor the x direction.

        // Literally a corner case! Ha! Ha!

        entity.y -= entity.vel.y;
        entity.vel.y = 0;
      }
    }

    // TODO: These should be static functions on MovingEntity.

    // A fast way to find collisions is to subdivide the map into a grid and
    // see if any individual square of the grid contains more than one item in
    // it.
    private static function moveEverything():void {
      var list:EntityList = entities.get("!nonblocking");
      var i:int = 0;

      // Move every non-static entity.
      for (i = 0; i < list.length; i++) {
        if (list[i].isStatic) continue;

        list[i].x += list[i].vel.x;
        list[i].y += list[i].vel.y;

        // TODO these should be private.
        list[i].oldVel = list[i].vel.clone();

        list[i].xColl = new EntityList([]);
        list[i].yColl = new EntityList([]);

        list[i].reset = false;
        list[i].flagsSet = false;

        list[i].touchingLeft = false;
        list[i].touchingRight = false;
        list[i].touchingTop = false;
        list[i].touchingBottom = false;
      }

      var grid:Array = makeGrid();

      // Set appropriate collision flags.

      // TODO: Need to rewrite MovingEntity.touching().

      // TODO: I feel like looping through the grid is strictly worse than looping
      // through every entity.
      for (i = 0; i < mapRef.widthInTiles; i++) {
        for (var j:int = 0; j < mapRef.widthInTiles; j++) {
          var contents:Array = grid[i][j];

          if (contents.length < 2) continue;

          for (var k:int = 0; k < contents.length; k++) {
            if (contents[k].isStatic) continue;

            var entity:MovingEntity = contents[k] as MovingEntity;

            if (entity.flagsSet) continue;
            entity.flagsSet = true;

            setColliders(entity, grid);
          }
        }
      }
    }

    private static function resolveCollisionGroup(group:Array, grid:Array):void {
      var selectedEntity:MovingEntity;
      var groupSize:int = group.length;

      for (var i:int = 0; i < groupSize; i++) {
        selectedEntity = null;

        for (var j:int = 0; j < group.length; j++) {
          // See if this entity can be freed.

          group[j].x -= group[j].oldVel.x;
          group[j].y -= group[j].oldVel.y;

          if (getColliders(group[j], grid).length == 0) {
            selectedEntity = group[j] as MovingEntity;
          }

          group[j].x += group[j].oldVel.x;
          group[j].y += group[j].oldVel.y;

          if (selectedEntity != null) {
            break;
          }
        }

        Util.assert(selectedEntity != null);
        Util.assert(!selectedEntity.reset);

        setColliders(selectedEntity, grid);

        if (selectedEntity.touchingRight) {
          var rightest:int = 0;
          for (i = 0; i < selectedEntity.xColl.length; i++) {
            rightest = Math.max(rightest, selectedEntity.xColl[i].x - selectedEntity.width);
          }

          selectedEntity.x = rightest;
        } else if (selectedEntity.touchingLeft) {
          var leftist:int = 9999;
          for (i = 0; i < selectedEntity.xColl.length; i++) {
            leftist = Math.min(leftist, selectedEntity.xColl[i].x + selectedEntity.xColl[i].width);
          }

          selectedEntity.x = leftist;
        }

        if (selectedEntity.touchingBottom) {
          var highest:int = 9999;
          for (i = 0; i < selectedEntity.yColl.length; i++) {
            highest = Math.min(highest, selectedEntity.yColl[i].y - selectedEntity.height);
          }

          selectedEntity.y = highest;
        } else if (selectedEntity.touchingTop) {
          var lowest:int = 0;
          for (i = 0; i < selectedEntity.yColl.length; i++) {
            lowest = Math.max(lowest, selectedEntity.yColl[i].y + selectedEntity.yColl[i].height);
          }

          selectedEntity.y = lowest;
        }

        selectedEntity.reset = true;

        group.remove(selectedEntity);
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

    private static function getCollisionGroups():Array {
      var e:EntityList = movingEntities();
      var groups:Array = [];

      while (e.length) {
        var curGroup:Dictionary = new Dictionary();
        curGroup[e.pop()] = true;

        var added:Boolean = true;

        while (added) {
          added = false;

          for (var o:Object in curGroup) {
            var curEnt:MovingEntity = o as MovingEntity;

            var c1:EntityList = curEnt.xColl;
            var c2:EntityList = curEnt.yColl;

            for (var k:int = 0; k < c1.length; k++) {
              if (curGroup[c1[k]]) continue;

              added = true;
              curGroup[c1[k]] = true;
            }

            for (var k:int = 0; k < c2.length; k++) {
              if (curGroup[c2[k]]) continue;

              added = true;
              curGroup[c2[k]] = true;
            }
          }
        }

        var arr:Array = Util.setToArray(curGroup);

        for (var i:int = 0; i < arr.length; i++) {
          e.remove(arr[i]);
        }

        groups.push(arr);
      }

      trace(groups);

      return groups;
    }

    private static function resolveCollisions():void {
      var i:int = 0;
      var grid:Array = makeGrid();
      var collisionGroups:Array = [];

      // TODO: Could store this before.
      for (i = 0; i < mapRef.widthInTiles; i++) {
        for (var j = 0; j < mapRef.widthInTiles; j++) {
          var objs:Array = grid[i][j];

          if (objs.length < 2) continue;

          var group:Array = [];

          for (var k = 0; k < objs.length; k++) {
            if (objs[k].isStatic) continue;

            group.push(objs[k]);
          }

          collisionGroups.push(group);
        }
      }

      for (i = 0; i < collisionGroups.length; i++) {
        resolveCollisionGroup(collisionGroups[i], grid);
      }
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

      resolveCollisions();

      camera.update();
      Util.dealWithVariableKeyRepeatRates();
    }
  }
}

