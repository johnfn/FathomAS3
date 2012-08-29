﻿package {
  public class Fathom {
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.display.MovieClip;
    import flash.display.Stage;
    import flash.events.Event;

    private static var gameloopID:int;
    private static var FPS:int = 0;
    private static var fpsFn:Function;
    private static var _camera:Camera;

    private static var _currentMode:int = 0;

    public static function get camera():Camera { return _camera; }

    public static var mapRef:Map;
    public static var fpsTxt:Text;
    public static var entities:EntityList = new EntityList([]);
    public static var container:Entity;
    public static var initialized:Boolean = false;
    public static var stage:Stage;

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
      return _currentMode;
    }

    public static function set currentMode(val:int):void {
      _currentMode = val;
    }

    public static function set showingFPS(b:Boolean):void {
      fpsTxt.visible = b;
    }

    //TODO: Eventually main class should extend this or something...
    public static function initialize(stage:Stage, m:Map, FPS:int = 30):void {
      // Inside of the Entity constructor, we assert Fathom.initialized, because all
      // MCs must be added to the container MC.

      Fathom.stage = stage;
      Fathom.initialized = true;

      Fathom.FPS = FPS;
      Fathom.container = new Entity();
      Fathom.stage.addChild(Fathom.container);
      Fathom.mapRef = m;

      Fathom.mapRef.loadNewMap(new Vec(0, 0));

      fpsFn = Hooks.fpsCounter();
      fpsTxt = new Text(200, 20);

      Util._initializeKeyInput(container);

      container.addEventListener(Event.ENTER_FRAME, update);

      // TODO: Swapping these calls causes insta-death. WUT.
      Fathom._camera = new Camera(stage).scaleBy(1).beBoundedBy(m);
    }

    //TODO: May want a better name than pause. freeze?
    public static function pause():void {
      _paused = true;
    }

    public static function resume():void {
      _paused = false;
    }

    public static function sortDepths():void {
      // sort by depth
      var entities:EntityList = Fathom.entities;
      entities.sort(function(a:Entity, b:Entity):int {
        return a.depth - b.depth;
      });

      for (var i:int = 0; i < entities.length; i++) {
        entities[i].raiseToTop();
      }
    }

    private static function update(event:Event):void {
      var updaters:EntityList;

      // TODO HACK
      if (currentMode == 4) return;

      // TODO: entities == Fathom.container.children

      if (_paused) {
        updaters = entities.get("updates-while-paused");
      } else {
        updaters = entities.get("updateable");
      }

      fpsTxt.text = fpsFn();

      for (var i:int = 0; i < updaters.length; i++) {
        var e:Entity = updaters[i];

        if (!e.modes().contains(currentMode)) continue;

        // This acts as a pseudo garbage-collector. We separate out the
        // destroyed() call from the clearMemory() call because we sometimes
        // want to destroy() an item halfway through its update() call, so the
        // actual destruction would have to wait until the end of the update.
        if (e.destroyed) {
          e.clearMemory();
          continue;
        }

        if (e.hidden) {
          continue;
        }

        e.emit("pre-update");
        e.update(entities);
        e.emit("post-update");
      }

      //TODO.
      if (currentMode == 0) {
        mapRef.update();
      }

      camera.update();
      Util.dealWithVariableKeyRepeatRates();
    }
  }
}

