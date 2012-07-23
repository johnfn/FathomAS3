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

    protected var groupArray:Array = [];
    protected var mcOffset:Vec;
    protected var mc:MovieClip;
    protected var color:Number;
    protected var children:Array = [];
    protected var wiggle:int = 0;
    protected var usesExternalMC:Boolean = false;

    // Allows for a fast check to see if this entity moves.
    protected var _isStatic:Boolean = true;

    // The Entity that contains this Entity, if there is one.
    protected var parent:Entity;

    public function get isStatic():Boolean { return _isStatic; }
    private function set isStatic(val:Boolean):void { _isStatic = val; }

    public function get childrenList():Array { return children; }
    private function set childrenList(val:Array):void { children = val; }

    public function get getmc():MovieClip { return mc; }

    //TODO: Make visible represent whether an mc actually exists for this Entity.
    function Entity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, color:Number = 0xFF0000, visible:Boolean = true, wiggle:int = 0):void {
      if (height == -1) height = width;

      super(x, y, this.width);

      if (!Fathom.initialized) {
        throw new Error("Util.initialize() has not been called. Failing.");
      }

      groupArray.push("updateable");
      this.height = height - wiggle * 2;
      this.width = width - wiggle * 2;
      this.color = color;
      this.setMCOffset(0, 0);
      this.parent = null;

      this.mc = new MovieClip();

      if (visible) {
        draw();
      }

      //TODO: I had this idea about how parents should bubble down events to children.
      if (Fathom.container) {
        Fathom.entities.add(this);
      }

      //TODO: Remove.
      this.__fathom = { events: {}
                      , entities: Fathom.entities
                      };

    }

    //TODO: there is some duplication here.
    public function fromExternalMC(mcClass:*, fixedSize:Boolean = false):Entity {
      //this.mc.graphics.clear();

      //TODO: Merge with show... somehow...

      this.usesExternalMC = true;

      var className:String = Util.className(mcClass);

      if (className == "String") {
        this.mc = new Fathom.MCPool[mcClass]();
        groupArray.push(mcClass);
      } else if (className == "MovieClip") {
        this.mc = mcClass;
      } else {
        this.mc = new mcClass();
      }

      if (fixedSize) {
        mc.width = this.width + wiggle * 2;
        mc.height = this.height + wiggle * 2;
      }

      // All Entities are added to the container, except the container itself, which
      // has to be bootstrapped onto the Stage. If Fathom.container does not exist, `this`
      // must be the container.
      if (Fathom.container) {
        Fathom.container.addChild(this);
      }

      return this;
    }

    public function set visible(v:Boolean):void { mc.visible = v; }
    public function get visible():Boolean { return mc.visible; }

    public function set alpha(v:Number):void { mc.alpha = v; }
    public function get alpha():Number { return mc.alpha; }

    public override function set x(v:Number):void { mc.x = Math.floor(v + mcOffset.x); _x = v; }
    public override function get x():Number { return _x; }

    public override function set y(v:Number):void { mc.y = Math.floor(v + mcOffset.y); _y = v; }
    public override function get y():Number { return _y; }

    public function set scaleX(v:Number):void { mc.scaleX = v; }
    public function get scaleX():Number { return mc.scaleX; }

    public function set scaleY(v:Number):void { mc.scaleY = v; }
    public function get scaleY():Number { return mc.scaleY; }

    public function gotoAndStop(f:int):void { mc.gotoAndStop(f); }
    public function gotoAndPlay(f:int):void { mc.gotoAndPlay(f); }

    public function get totalFrames():int { return mc.totalFrames; }

    public function set currentFrame(v:int):void { mc.currentFrame = v; }
    public function get currentFrame():int { return mc.currentFrame; }

    public function play():void { mc.play(); }

    protected function setMCOffset(x:int, y:int):void {
      this.mcOffset = (new Vec(wiggle, wiggle)).add(new Vec(x, y));
    }

    protected function draw():void {
      mc.graphics.beginFill(color);
      mc.graphics.drawRect(0, 0, this.width + wiggle * 2, this.height + wiggle * 2);
      mc.graphics.endFill();
    }

    // Pass in the x-coordinate of your velocity, and this'll orient
    // the Entity in that direction.
    protected function face(dir:int):void {
      if (dir > 0 && this.mc.scaleX < 0) {
        this.mc.scaleX *= -1;
        return;
      }
      if (dir < 0 && this.mc.scaleX > 0) {
        this.mc.scaleX *= -1;
        return;
      }
    }

    public function disappearAfter(frames:int):Entity {
      var timeLeft:int = frames;
      var that:Entity = this;

      listen(function():void {
        if (timeLeft-- == 0) {
          that.destroy();
        }
      });

      return this;
    }

    public function raiseToTop():void {
      //TODO: This depends on the visibility parameter.
      if (this.mc.parent) {
        this.mc.parent.setChildIndex(this.mc, this.mc.parent.numChildren - 1);
      }
    }

    // TODO: This function needs some work.
    public function addChild(child:Entity):void {
      children.push(child);
      child.parent = this;

      //TODO: Eventually remove this, visible should be default.
      child.visible = true;

      // All children are initially managed by the master entity list.
      // In this case we don't want that to be true.

      //Fathom.entities.remove(child);

      mc.addChild(child.mc);
    }

    // Remove child: The child entity does not belong to this entity as a child.
    // It continues to exist in the game.
    public function removeChild(child:Entity):void {
      child.visible = false;
      children.remove(child);
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

    public function currentlyObstructing(...args):EntityList {
      return currentlyTouching.apply(this, args.concat("!Ladder"));
    }

    /* This causes the Entity to cease existing in-game. The only way to
       bring it back is to call show(). */

    // TODO: Naming this function is very hard. I want something that
    // connotates removing it from the global entities list, but not
    // destroying the actual object itself (it can be brought back later.)

    // TODO: Aha: removeFromScene()
    public function hide():void {
      for (var i:int = 0; i < children.length; i++){
        children[i].hide();
      }

      if (this.parent) this.parent.removeChild(this);

      /*
      Fathom.entities.remove(this);
      if (this.parent) parent.removeChild(mc);
      */
      hidden = true;
    }

    /* This causes the Entity to exist in the game. You should only call
       this after a call to hide(). */
    public function show():void {
      Util.assert(!destroyed);

      for (var i:int = 0; i < children.length; i++){
        children[i].show();
      }

      /*
      Fathom.entities.add(this);
      if (this.parent) parent.addChild(mc);
      */
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
      if (mc && mc.parent) {
        mc.parent.removeChild(mc);
      }

      if (parent) parent.removeChild(this);
      mc = null;
      destroyed = true;
      Fathom.entities.remove(this);
    }

    //TODO: Could add all superclasses.
    //TODO: "updateable" is the norm. "noupdate" should be a group.
    //TODO: There is a possible namespace collision here. Should prob make it impossible to manually add groups.
    //TODO: I've decided I don't like strings. Enumerations are better.
    public function groups():Array {
      return groupArray.concat(Util.className(this));
    }

    public function collides(other:Entity):Boolean {
      return (!(this == other)) && touchingRect(other);
    }

    public function collidesPt(point:Point):Boolean { return mc.hitTestPoint(point.x, point.y); }

    public function update(e:EntityList):void {}

    public override function toString():String {
      return "[" + Util.className(this) + super.toString() + "]";
    }

    public function depth():int { return 0; }
  }
}
