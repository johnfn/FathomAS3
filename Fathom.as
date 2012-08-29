package {
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

      Fathom._camera = new Camera(stage).scaleBy(1).beBoundedBy(m);
    }

    /* This stops everything. The only conceivable use would be
       possibly for some sort of end game situation. */
    public static function stop():void {
      container.removeEventListener(Event.ENTER_FRAME, update);
    }

    private static function update(event:Event):void {
      // We copy the entity list so that it doesn't change while we're
      // iterating through it.
      var list:EntityList = entities.clone();

      // TODO: entities == Fathom.container.children
      fpsTxt.text = fpsFn();

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

