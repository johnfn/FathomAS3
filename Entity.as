package {
  import flash.display.MovieClip;
  import flash.geom.Point;
  import flash.utils.getQualifiedClassName;

  import Hooks;
  import Util;
  import MagicArray;

  public class Entity extends Rect {
    public var __fathom:Object;
    public var destroyed:Boolean = false;
    public var hidden:Boolean = false;

    protected var mc:MovieClip;
    protected var color:Number;
    protected var children:Array = [];
    protected var wiggle:int = 0;
    protected var usesExternalMC:Boolean = false;

    //TODO: Make visible represent whether an mc actually exists for this Entity.
    function Entity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, color:Number = 0xFF0000, visible:Boolean = true, wiggle:int = 0, baseMC:Class = null):void {
      if (height == -1) height = width;

      this.height = height - wiggle * 2;
      this.width = width - wiggle * 2;
      this.color = color;

      if (baseMC) {
        this.mc = new baseMC();
        this.usesExternalMC = true;
      } else {
        this.mc = new MovieClip();
      }

      super(x, y, this.width);

      if (!Fathom.stage) {
      	throw new Error("Util.initialize() has not been called. Failing.");
      }

      if (visible) {
        show();
        draw(this.height + wiggle * 2);
        Fathom.stage.addChild(mc);
      } else {
        Fathom.entities.add(this);
      }

      this.__fathom = { uid: Util.getUniqueID()
                      , events: {}
                      , entities: Fathom.entities
                      };
    }

    public function set visible(v:Boolean):void { mc.visible = v; }
    public function get visible():Boolean { return mc.visible; }

    public function set alpha(v:Number):void { mc.alpha = v; }
    public function get alpha():Number { return mc.alpha; }

    public override function set x(v:Number):void { mc.x = Math.floor(v + wiggle); _x = v; }
    public override function get x():Number { return _x; }

    public override function set y(v:Number):void { mc.y = Math.floor(v + wiggle); _y = v; }
    public override function get y():Number { return _y; }

    protected function draw(size:int):void {
      if (!this.usesExternalMC) {
        mc.graphics.beginFill(color);
        mc.graphics.drawRect(0, 0, size, size);
        mc.graphics.endFill();
      }
    }

    // TODO: This function needs some work.
    public function addChild(child:Entity):void {
      children.push(child);

      // All children are implicitly managed by the master entity list, but
      // in this case we don't want that to be true.

      Fathom.entities.remove(child);
    }

    public function entities():EntityList {
      return __fathom.entities;
    }


    /*
    public function addEvent(event:Function):Entity {
      on("post-update", event);
    }
    */

    //TODO: I don't think I like this interface.
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
        __fathom.events[event].remove(callback);
      } else {
        __fathom.events[event] = [];
      }

      return this;
    }

    public function listen(callback:Function = null):Entity {
      on("pre-update", callback);

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

      return Fathom.entities.get.apply(this, args.concat(touchesMe));
    }

    /* This causes the Entity to cease existing in-game. The only way to
       bring it back is to call show(). */

    // TODO: Naming this function is very hard. I want something that
    // connotates removing it from the global entities list, but not
    // destroying the actual object itself (it can be brought back later.)
    public function hide():void {
      for (var i:int = 0; i < children.length; i++){
        children[i].hide();
      }

      Fathom.entities.remove(this);
      mc.visible = false;
      hidden = true;
    }

    /* This causes the Entity to exist in the game. You should only call
       this after a call to hide(). */
    public function show():void {
      Util.assert(!destroyed);

      for (var i:int = 0; i < children.length; i++){
        children[i].show();
      }

      Fathom.entities.add(this);
      mc.visible = true;
      hidden = false;
    }

    /* This permanently removes an Entity. It can't be add()ed back. */
    public function destroy():void {
      for (var i:int = 0; i < children.length; i++){
        children[i].destroy();
      }

      destroyed = true;
    }

    public function clearMemory():void {
      hide();

      __fathom = null;
      if (mc.parent) mc.parent.removeChild(mc);
      mc = null;
      destroyed = true;
    }

    //TODO: Could add all superclasses.
    //TODO: "updateable" is the norm. "noupdate" should be a group.
    //TODO: There is a possible namespace collision here. Should prob make it impossible to manually add groups.
    //TODO: I've decided I don't like strings. Enumerations are better.
    public function groups():Array {
      return ["updateable"].concat(Util.className(this));
    }

    public function collides(other:Entity):Boolean {
      return (!(this == other)) && touchingRect(other);
    }

    public function collidesPt(point:Point):Boolean { return mc.hitTestPoint(point.x, point.y); }

    public function update(e:EntityList):void {}

    public override function toString():String {
      return "[" + Util.className(this) + super.toString() + "]";
    }

    public function depth():Number { return 0; }
  }
}
