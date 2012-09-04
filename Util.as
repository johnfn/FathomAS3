package {
  public class Util {
    import flash.system.fscommand;
    import flash.utils.*;
    import flash.events.KeyboardEvent;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.utils.getQualifiedClassName;

    public static var uid:Number = 0;
    public static var Key:Object = keysToKeyCodes();
    private static var keyStates:Array = [];

    //TODO: Should move Array.prototype stuff into separate ArrayExtensions class.

    // Array::indexOf only works with String values.
    Array.prototype.getIndex = function(val:*):int {
      for (var i:int = 0; i < this.length; i++) {
        if (this[i] == val) return i;
      }

      return -1;
    }

    // TODO: Calls k O(n^2) times; can reduce to O(n) with little trouble.

    /* Ties each element e in the array to a value k(e) and sorts the array
       how you'd sort the values from low to high. */
    Array.prototype.sortBy = function(k:Function):void {
      this.sort(function(a:*, b:*):int {
        return k(a) - k(b);
      });
    }

    Array.prototype.contains = function(val:*):Boolean {
      return this.getIndex(val) != -1;
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

    Array.prototype.extend = function(a:Array):void {
      for (var i:int = 0; i < a.length; i++) {
        this.push(a[i]);
      }
    }

    Sprite.prototype.asVec = function():Vec {
      return new Vec(this.x, this.y);
    }

    public static function id(x:*):* {
      return x;
    }

    // Divide a by b, always rounding up unless a % b == 0.
    // Looks simple, doesn't it? But see: http://stackoverflow.com/questions/921180/how-can-i-ensure-that-a-division-of-integers-is-always-rounded-up
    public static function divRoundUp(a:Number, b:Number):Number {
      return (a + b - 1) / b;
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
      if (!b) {
        var e:Error = new Error("Assertion failed.");
        trace(e.getStackTrace());
        fscommand("quit");
        throw e;
      }
    }

    public static function epsilonEq(a:Number, b:Number, threshold:Number):Boolean {
      return Math.abs(a - b) < threshold;
    }

    public static function getUniqueID():Number {
      return ++uid;
    }

    // This function is currently broken if val is an object, and there's no
    // easy way to fix it.

    //public static function make2DArrayVal(width:int, height:int, val:*):Array {
    //  return make2DArrayFn(width, height, function():* { return val; });
    //}

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

    // With thanks to http://kirill-poletaev.blogspot.com/2010/07/rotate-object-to-mouse-using-as3.html
    public static function rotateToFace(pointer:Vec, target:Vec):Number {
      var cx:Number = target.x - pointer.x;
      var cy:Number = target.y - pointer.y;

      var radians:Number = Math.atan2(cy, cx);
      var degrees:Number = radians * 180 / Math.PI;

      return degrees;
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

    private static function _keyDown(event:KeyboardEvent):void {
      var keystate:KeyState = keyStates[event.keyCode];

      if (keystate.state != KeyState.KEYSTATE_JUST_DOWN && keystate.state != KeyState.KEYSTATE_DOWN) {
        keystate.state = KeyState.KEYSTATE_JUST_DOWN;
      }
    }

    private static function _keyUp(event:KeyboardEvent):void {
      var keystate:KeyState = keyStates[event.keyCode];

      if (keystate.state != KeyState.KEYSTATE_JUST_UP && keystate.state != KeyState.KEYSTATE_UP) {
        keystate.state = KeyState.KEYSTATE_JUST_UP;
      }
    }

    // This is very frustrating.

    // This method is called from an onEnterFrame function. Everything will
    // work correctly as long as this is called FPS times per second or so, as
    // to properly flush the keys through.
    public static function dealWithVariableKeyRepeatRates():void {
      for (var i:int = 0; i < keyStates.length; i++) {
        if (keyStates[i].state == KeyState.KEYSTATE_JUST_UP) {
          keyStates[i].state = KeyState.KEYSTATE_UP;
        }

        if (keyStates[i].state == KeyState.KEYSTATE_JUST_DOWN) {
          keyStates[i].state = KeyState.KEYSTATE_DOWN;
        }
      }
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
      return (keyStates[which].state == KeyState.KEYSTATE_JUST_UP);
    }

    // Has a key just been pressed?

    public static function keyRecentlyDown(which:int):Boolean {
      return (keyStates[which].state == KeyState.KEYSTATE_JUST_DOWN);
    }

    // You should never have to call this function.
    // TODO: Move into Fathom, I guess.
    public static function _initializeKeyInput(container:Sprite):void {
      Fathom.stage.addEventListener(KeyboardEvent.KEY_DOWN, _keyDown, false, 0, true);
      Fathom.stage.addEventListener(KeyboardEvent.KEY_UP, _keyUp, false, 0, true);

      for (var i:int = 0; i < 255; i++) {
        keyStates[i] = new KeyState();
      }
    }

    private static function keysToKeyCodes():Object {
      var res:Object = {};

      res["Left"]  = 37;
      res["Up"]    = 38;
      res["Right"] = 39;
      res["Down"]  = 40;

      // Add A - Z.
      for (var k:int = 65; k <= 65 + 26; k++) {
        res[String.fromCharCode(k)] = k;
      }

      return res;
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
