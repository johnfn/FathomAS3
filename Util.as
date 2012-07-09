package {
  public class Util {
    import flash.utils.*;
    import flash.events.KeyboardEvent;
    import flash.display.DisplayObject;
    import flash.display.Stage;
    import flash.utils.getQualifiedClassName;

    public static var uid:Number = 0;
    public static var entities:EntityList = new EntityList([]);
    public static var Key:Object = {};
    public static var stage:Stage;

    private static var keyStates:Array = new Array(255);

    // Array::indexOf only works with String values.
    Array.prototype.getIndex = function(val:*):int {
      for (var i:int = 0; i < this.length; i++) {
        if (this[i] == val) return i;
      }

      return -1;
    }

    // Remove all occurances of item from array.
    Array.prototype.remove = function(item:*):void {
      for (var i:int = 0; i < this.length; i++) {
        if (this[i] == item) {
          this.splice(i, 1);
          i--;
        }
      }
    }

    public static function id(x:*):* {
      return x;
    }

    public static function sign(x:Number):Number {
      if (x > 0) return  1;
      if (x < 0) return -1;
                 return  0;
    }

    public static function className(c:*):String {
      var qualifiedName:String = getQualifiedClassName(c);
      if (qualifiedName.indexOf(":") == -1) return qualifiedName;
      var split:Array = qualifiedName.split(":");

      return split[split.length - 1];
    }

    public static function assert(b:Boolean):void {
      if (!b) throw "Assertion failed.";
    }

    public static function epsilonEq(a:Number, b:Number, threshold:Number):Boolean {
      return Math.abs(a - b) < threshold;
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

    private static function update():void {
      entities.update();
    }

    private static function _keyDown(event:KeyboardEvent):void {
      var keystate:KeyState = keyStates[event.keyCode];

      if (keystate.state != KeyState.KEYSTATE_JUST_DOWN && keystate.state != KeyState.KEYSTATE_DOWN) {
        keystate.state = KeyState.KEYSTATE_JUST_DOWN;
      }
      if (keystate.timeoutID != 0) clearTimeout(keystate.timeoutID);
      keystate.timeoutID = setTimeout(function():void {
        keystate.state = KeyState.KEYSTATE_DOWN;
        keystate.timeoutID = 0;
      }, 50);
    }

    private static function _keyUp(event:KeyboardEvent):void {
      var keystate:KeyState = keyStates[event.keyCode];

      if (keystate.state != KeyState.KEYSTATE_JUST_UP && keystate.state != KeyState.KEYSTATE_UP) {
        keystate.state = KeyState.KEYSTATE_JUST_UP;
      }
      if (keystate.timeoutID != 0) clearTimeout(keystate.timeoutID);
      keystate.timeoutID = setTimeout(function():void {
        keystate.state = KeyState.KEYSTATE_UP;
        keystate.timeoutID = 0;
      }, 50);
    }

    // Is a key currently up?

    public static function keyIsUp(which:int):Boolean {
      return keyStates[which].state == KeyState.KEYSTATE_UP || keyStates[which].state == KeyState.KEYSTATE_JUST_UP;
    }

    // Is a key currently down?

    public static function keyIsDown(which:int):Boolean {
      return keyStates[which].state == KeyState.KEYSTATE_JUST_DOWN || keyStates[which].state == KeyState.KEYSTATE_DOWN;
    }

    // Has a key just been released?

    public static function keyRecentlyUp(which:int):Boolean {
      if (keyStates[which].state == KeyState.KEYSTATE_JUST_UP) {
        keyStates[which].state = KeyState.KEYSTATE_UP;

        return true;
      }
      return false;
    }

    // Has a key just been pressed?

    public static function keyRecentlyDown(which:int):Boolean {
      if (keyStates[which].state == KeyState.KEYSTATE_JUST_DOWN) {
        keyStates[which].state = KeyState.KEYSTATE_DOWN;

        return true;
      }
      return false;
    }

    private static function initializeKeyInput(stage:Stage):void {
      stage.addEventListener(KeyboardEvent.KEY_DOWN, _keyDown);
      stage.addEventListener(KeyboardEvent.KEY_UP, _keyUp);

      for (var i:int = 0; i < 255; i++) {
        keyStates[i] = new KeyState();
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

class KeyState {
  public static var KEYSTATE_JUST_DOWN:int = 0;
  public static var KEYSTATE_DOWN:int      = 1;
  public static var KEYSTATE_JUST_UP:int   = 2;
  public static var KEYSTATE_UP:int        = 3;

  public var state:int = KEYSTATE_UP;
  public var timeoutID:int = 0;
}
