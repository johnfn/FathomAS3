package {
  public class Fathom {
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.display.Stage;

    private static var gameloopID:int;
    private static var FPS:int = 0;

    public static var entities:EntityList = new EntityList([]);
    public static var stage:Stage;
    public static var _paused:Boolean = false;

    public static function get paused():Boolean { return _paused; }

    public static function initialize(stage:Stage, FPS:int = 30):void {
      Fathom.FPS = FPS;
      Fathom.stage = stage;

      Util._initializeKeyInput(stage);
      gameloopID = setInterval(update, 1000 / FPS);
    }

    //TODO: May want a better name than pause. freeze?
    public static function pause():void {
      _paused = true;
    }

    public static function resume():void {
      _paused = false;
    }

    private static function update():void {
      var updaters:EntityList;
      if (_paused) {
        updaters = entities.get("updates-while-paused");
      } else {
        updaters = entities.get("updateable");
      }

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
