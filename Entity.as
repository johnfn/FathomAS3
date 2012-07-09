package {
  import flash.display.MovieClip;
  import flash.geom.Point;
  import flash.utils.getQualifiedClassName;

  import Hooks;
  import Util;
  import MagicArray;

  public class Entity extends Rect implements IEqual {
    public var __fathom:Object;

    internal var mc:MovieClip;
    internal var color:Number;

    function Entity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, color:Number = 0xFF0000, visible:Boolean = true):void {
      if (height == -1) height = width;

      this.height = height;
      this.width = width;
      this.color = color;
      this.mc = new MovieClip();
      this.mc.x = x;
      this.mc.y = y;

      super(x, y, width);

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

    public function set visible(v:Boolean):void { mc.visible = v; }
    public function get visible():Boolean { return mc.visible; }

    public function set alpha(v:Number):void { mc.alpha = v; }
    public function get alpha():Number { return mc.alpha; }

    private function draw(width:Number, height:Number, color:Number):void {
      mc.graphics.beginFill(color);
      mc.graphics.drawRect(0, 0, width, height);
      mc.graphics.endFill();
    }

    public function entities():EntityList {
      return __fathom.entities;
    }


    /*
    public function addEvent(event:Function):Entity {
      on("post-update", event);
    }
    */

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

      trace(events.getIndex(callback));
      if (callback != null) {
        __fathom.events[event].remove(callback);
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

    public function touching(...args):Boolean {
      return currentlyTouching.apply(this, args).length > 0;
    }

    // TODO: Needs a better name.
    public function currentlyTouching(...args):EntityList {
      var that:* = this;

      // It is important that we use *their* collision method, not ours.
      // TODO: This will lead to disaster down the line (imagine colliding two maps!)

      var touchesMe:Function = function(other:Entity):Boolean {
        return other.collides(that);
      };

      return Util.entities.get.apply(this, args.concat(touchesMe));
    }

    public function die():void { __fathom.entities.remove(this); }

    //TODO: "updateable" is the norm. "noupdate" should be a group.
    //TODO: There is a possible namespace collision here. Should prob make it impossible to manually add groups.
    public function groups():Array { return ["updateable"].concat(Util.className(this)); }

    public function collides(other:Entity):Boolean {
      return (!eq(other)) && touchingRect(other);
    }

    public function collidesPt(point:Point):Boolean { return mc.hitTestPoint(point.x, point.y); }

    public function update(e:EntityList):void {
      mc.x = x;
      mc.y = y;
    }

    public function depth():Number { return 0; }
  }
}
