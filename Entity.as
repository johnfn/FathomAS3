package {
  import flash.display.MovieClip;
  import flash.geom.Point;

  import Hooks;
  import Util;

  public class Entity extends MovieClip {
    private var __fathom:Object;
    internal var gfxHeight:Number;
    internal var gfxWidth:Number;
    internal var color:Number;

    function Entity(x:Number = 0, y:Number = 0, gfxWidth:Number = 20, gfxHeight:Number = -1, color:Number = 0xFF0000, visible:Boolean = true):void {
      if (gfxHeight == -1) gfxHeight = gfxWidth;

      this.gfxHeight = gfxHeight;
      this.gfxWidth = gfxWidth;
      this.color = color;
      this.x = x;
      this.y = y;

      super();

      Util.entities.add(this);

      if (!Util.stage) {
      	throw new Error("Util.initialize() has not been called. Failing.");
      }

      if (visible) {
        draw(gfxWidth, gfxHeight, color);
        Util.stage.addChild(this);
      }

      this.__fathom = { uid: Util.getUniqueID()
                      , events: {}
                      , entities: Util.entities
                      };
    }

    private function draw(gfxWidth:Number, gfxHeight:Number, color:Number):void {
      graphics.beginFill(color);
      graphics.drawRect(0, 0, gfxWidth, gfxHeight);
      graphics.endFill();
    }

    public function entities():Entities {
      return __fathom.entities;
    }

    public function on(event:String, callback:Function):Entity {
      var events:Array = __fathom.events[event] || [];
      if (! (callback in events)) {
        events.push(callback);
      }

      __fathom.events[event] = events;

      return this;
    }

    public function off(event:String, callback:Function = null):Entity {
      var events:Array = __fathom.events[event];
      if (!events) {
        throw "Don't have that event!";
      }

      if (callback != null) {
        __fathom.events[event] = events.splice(events.indexOf(callback), 1);
      } else {
        __fathom.events[event] = [];
      }

      return this;
    }

    public function emit(event:String):Entity {
      if (event in __fathom.events) {
        for each (var hook:Function in __fathom.events[event]) {
          hook.call(this)
        }
      }

      return this;
    }

    public function touchesAnything():Boolean {
      var that:* = this;

      return (Util.entities.any(function(other:Entity):Boolean {
        return other.collides(that);
      }));
    }

    public function die():void { __fathom.entities.remove(this); }

    public function groups():Array { return ["updateable"]; }

    public function eq(other:Entity):Boolean { return __fathom.uid == other.__fathom.uid; }

    public function collides(other:Entity):Boolean { return (!eq(other)) && hitTestObject(other); }

    public function update(e:Entities):void {}

    public function depth():Number { return 0; }
  }
}
