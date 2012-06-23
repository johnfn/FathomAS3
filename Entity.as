package {
  import flash.display.MovieClip;
  import flash.geom.Point;

  import Hooks;
  import Util;
  import MagicArray;

  public class Entity {
    public var __fathom:Object;
    //public var pos:Vec;

    internal var mc:MovieClip;
    internal var height:Number;
    internal var width:Number;
    internal var color:Number;
    internal var _pos:Vec;

    function Entity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, color:Number = 0xFF0000, visible:Boolean = true):void {
      if (height == -1) height = width;

      this.height = height;
      this.width = width;
      this.color = color;
      this.mc = new MovieClip();
      this.mc.x = x;
      this.mc.y = y;
      this.pos = new Vec(x, y);

      super();

      if (!Util.stage) {
      	throw new Error("Util.initialize() has not been called. Failing.");
      }

      if (visible) {
        Util.entities.add(this);
        draw(width, height, color);
        Util.stage.addChild(mc);
      }

      this.__fathom = { uid: Util.getUniqueID()
                      , events: {}
                      , entities: Util.entities
                      };
    }

    public function set pos(val:Vec):void {
      this._pos = val;
      this.mc.x = this._pos.x;
      this.mc.y = this._pos.y;
    }

    public function get pos():Vec { return this._pos; }

    private function draw(width:Number, height:Number, color:Number):void {
      trace(color);
      trace(width, height);
      mc.graphics.beginFill(color);
      mc.graphics.drawRect(0, 0, width, height);
      mc.graphics.endFill();
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
      var footY:int = pos.y + this.height;
      var pts:MagicArray = new MagicArray();
      var that:Entity = this;

      for (var footX:int = pos.x + 2; footX < pos.x + this.width - 2; footX += 2) {
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

    public function collides(other:Entity):Boolean { return (!eq(other)) && mc.hitTestObject(other.mc); }

    public function collidesPt(point:Point):Boolean { return mc.hitTestPoint(point.x, point.y); }

    public function update(e:EntityList):void {}

    public function depth():Number { return 0; }
  }
}
