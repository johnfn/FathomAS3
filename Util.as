package {
  public class Util {
    import flash.utils.*;
    import flash.events.KeyboardEvent;
    import flash.display.DisplayObject;
    import flash.display.Stage;

    public static var uid:Number = 0;
    public static var entities:EntityList = new EntityList([]);
    public static var Key:Object = {};
    public static var stage:Stage;

    private static var keysDown:Array = new Array(255);
    private static var keysRecentlyUp:Array = new Array(255);

    public static function id(x:*):* {
      return x;
    }

    public static function getUniqueID():Number {
      return ++uid;
    }

    public static function make2DArrayFn(width:int, height:int, fn:Function):Array {
      var result:Array = new Array(width);

      for (var i:int = 0; i < width; i++) {
        result[i] = new Array(height);
        for (var j:int = 0; j < height; j++) {
          result[i][j] = fn(i, j);
        }
      }

      return result;
    }

    public static function foreach2D(a:Array, fn:Function):void {
      for (var i:int = 0; i < a.length; i++) {
        for (var j:int = 0; j < a[0].length; j++) {
          fn(i, j, a[i][j]);
        }
      }
    }

    public static function make2DArray(width:int, height:int, defaultValue:*):Array {
      return make2DArrayFn(width, height, function(x:int, y:int):* { return defaultValue; });
    }

    public static function movementVector():Vec {
      var x:int = ((keyIsDown(Key.Right) ? 1 : 0) - (keyIsDown(Key.Left) ? 1 : 0));
      var y:int = ((keyIsDown(Key.Down)  ? 1 : 0) - (keyIsDown(Key.Up)   ? 1 : 0));

      return new Vec(x, y);
    }


    public static function randRange(low:int, high:int):int {
      return low + Math.floor(Math.random() * (high - low));
    }

    public static function keyIsDown(which:int):Boolean {
      return keysDown[which];
    }

    private static function update():void {
      entities.update();
    }

    private static function _keyDown(event:KeyboardEvent):void {
      keysDown[event.keyCode] = true;
    }

    private static function _keyUp(event:KeyboardEvent):void {
      keysDown[event.keyCode] = false;

      if (keysRecentlyUp[event.keyCode] != 0) {
        clearTimeout(keysRecentlyUp[event.keyCode]);
      }

      keysRecentlyUp[event.keyCode] = setTimeout(function():void {
        keysRecentlyUp[event.keyCode] = 0;
      }, 500);
    }

    public static function keyRecentlyReleased(which:int):Boolean {
      if (keysRecentlyUp[which]) {
        clearTimeout(keysRecentlyUp[which]);
        keysRecentlyUp[which] = 0;
        return true;
      }

      return false;
    }

    private static function initializeKeyInput(stage:Stage):void {
      stage.addEventListener(KeyboardEvent.KEY_DOWN, _keyDown);
      stage.addEventListener(KeyboardEvent.KEY_UP, _keyUp);

      for (var i:int = 0; i < 255; i++) {
        keysDown[i] = false;
      }

      Key["Left"]  = 37;
      Key["Up"]    = 38;
      Key["Right"] = 39;
      Key["Down"]  = 40;

      // Add A - Z.
      for (var k:int = 65; k <= 65 + 26; k++) {
        Key[String.fromCharCode(k)] = k;
      }
    }

    public static function initialize(stage:Stage):void {
      Util.stage = stage;

      initializeKeyInput(stage);
      setInterval(update, 1000/30);
    }
  }
}
