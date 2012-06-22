package {
  import flash.display.MovieClip;
  import flash.geom.Point;

  import Hooks;
  import Util;
  import MagicArray;

  public class Entity extends MovieClip {
    public var __fathom:Object;
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

      if (!Util.stage) {
      	throw new Error("Util.initialize() has not been called. Failing.");
      }

      if (visible) {
        Util.entities.add(this);
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

    public function entities():EntityList {
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
        var hooks:Array = __fathom.events[event];

        for (var i:int = 0; i < hooks.length; i++){
          var hook:Function = hooks[i];

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

    public function touchesGround():Boolean {
      var footY:int = y + this.gfxHeight;
      var pts:MagicArray = new MagicArray();
      var that:Entity = this;

      for (var footX:int = x + 2; footX < this.x + this.gfxWidth - 2; footX += 2) {
        pts.push(new Point(footX, footY));
      }

      return pts.myMap(function(p:Point):Boolean {
        return Util.entities.exclude(that).any(function(other:Entity):Boolean {
          if (other.collidesPt(p)) {
            trace(other.__fathom.uid);
          }
          return other.collidesPt(p);
        });
      }).any();
    }

    public function die():void { __fathom.entities.remove(this); }

    public function groups():Array { return ["updateable"]; }

    public function eq(other:Entity):Boolean { return __fathom.uid == other.__fathom.uid; }

    public function collides(other:Entity):Boolean { return (!eq(other)) && hitTestObject(other); }

    public function collidesPt(point:Point):Boolean { return hitTestPoint(point.x, point.y); }

    public function update(e:EntityList):void {}

    public function depth():Number { return 0; }
  }
}
