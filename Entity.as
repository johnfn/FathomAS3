package {
  import flash.display.MovieClip;
  import flash.geom.Point;

  import Hooks;
  import Util;

  public class Entity extends MovieClip {
    private var __fathom:Object;

    public var vx:int = 0;
    public var vy:int = 0;

    function Entity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, color:Number = 0xFF0000):void {
      if (height == -1) height = width;

      this.x = x;
      this.y = y;

      graphics.beginFill(color);
      graphics.drawRect(x, y, width, height);
      graphics.endFill();

      this.__fathom = { uid: Util.getUniqueID()
                      , events: {}
                      , entities: Util.entities
                      };
      Util.entities.add(this)

      on("pre-update", Hooks.rpgLike(5));
      on("pre-update", Hooks.decel());
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

    public function die():void { __fathom.entities.remove(this); }

    public function groups():Array { return ["updateable"]; }

    public function eq(other:Entity):Boolean { return __fathom.uid == other.__fathom.uid; }

    public function collides(other:Entity):Boolean { return (!eq(other)) && hitTestObject(other); }

    public function update(e:Entities):void {}

    public function depth():Number { return 0; }
  }
}
