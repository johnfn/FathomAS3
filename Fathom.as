package {
  public class Fathom {
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.display.MovieClip;
    import flash.events.Event;

    private static var gameloopID:int;
    private static var FPS:int = 0;
    private static var fpsFn:Function;

    public static var fpsTxt:Text;
    public static var entities:EntityList = new EntityList([]);
    public static var container:MovieClip;
    public static var _paused:Boolean = false;

    public static function get paused():Boolean { return _paused; }

    public static function set showFPS(b:Boolean) {
      fpsTxt.visible = b;
    }

    public static function initialize(container:MovieClip, FPS:int = 30):void {
      Fathom.FPS = FPS;
      Fathom.container = container;

      fpsFn = Hooks.fpsCounter();
      fpsTxt = new Text(200, 20);

      Util._initializeKeyInput(container);

      container.addEventListener(Event.ENTER_FRAME, update);
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
        return a.depth() - b.depth();
      });

      for (var i:int = 0; i < entities.length; i++) {
        entities[i].raiseToTop();
      }
    }

    private static function update(event:Event):void {
      var updaters:EntityList;
      if (_paused) {
        updaters = entities.get("updates-while-paused");
      } else {
        updaters = entities.get("updateable");
      }

      fpsTxt.text = fpsFn();

      for (var i:int = 0; i < updaters.length; i++) {
        var e:Entity = updaters[i];

        // This acts as a pseudo garbage-collector. We
        // separate out the destroyed() call from the clearMemory() call because
        // we sometimes want to destroy() an item halfway through its update() call,
        // so the actual destruction would have to wait until the end of the update.
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
    }
  }
}
