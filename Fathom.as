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

    public static function pause():void {
      _paused = true;

      clearInterval(gameloopID);
    }

    public static function resume():void {
      _paused = false;

      gameloopID = setInterval(update, 1000 / Fathom.FPS);
    }

    private static function update():void {
      var updaters:EntityList;
      if (_paused) {
        updaters = this.get("updates-while-paused");
      } else {
        updaters = this.get("updateable");
      }

      for (var i:int = 0; i < updaters.length; i++) {
        var e:Entity = updaters[i];

        // There is a possibility that an earlier update() caused this entity
        // to destroy itself. If so, skip it.
        if (e.destroyed) continue;

        e.emit("pre-update");
        e.update(this);
        e.emit("post-update");
      }
    }
  }
}
