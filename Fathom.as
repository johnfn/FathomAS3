package {
  public class Fathom {
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.display.Stage;

    private static var gameloopID:int;
    private static var FPS:int = 0;

    public static var entities:EntityList = new EntityList([]);
    public static var stage:Stage;

    public static function initialize(stage:Stage, FPS:int = 30):void {
      Fathom.FPS = FPS;
      Fathom.stage = stage;

      Util._initializeKeyInput(stage);
      gameloopID = setInterval(update, 1000 / FPS);
    }

    public static function pause():void {
      clearInterval(gameloopID);
    }

    public static function resume():void {
      gameloopID = setInterval(update, 1000 / Fathom.FPS);
    }

    private static function update():void {
      entities.update();
    }
  }
}
