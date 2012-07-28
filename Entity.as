package {
  import flash.display.MovieClip;
  import flash.geom.Point;
  import flash.utils.getQualifiedClassName;
  import flash.debugger.enterDebugger;

  import Hooks;
  import Util;
  import MagicArray;

  public class Entity extends Rect {
    private var events:Object = {};
    // This indicates that the object should be destroyed.
    // The update loop in Fathom will eventually destroy it.
    public var destroyed:Boolean = false;
    public var hidden:Boolean = false;

    protected var groupArray:Array = [];
    protected var color:Number;
    protected var children:Array = [];
    protected var wiggle:int = 0;
    protected var usesExternalMC:Boolean = false;
    protected var _ignoresCollisions:Boolean = false;

    protected var mcOffset:Vec;
    protected var mc:MovieClip;
    protected var childrenContainer:MovieClip = new MovieClip();
    protected var initialSize:Vec;

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
    function Entity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, visible:Boolean = true, wiggle:int = 0):void {
      if (height == -1) height = width;

      super(x, y, this.width);

      if (!Fathom.initialized) {
        throw new Error("Util.initialize() has not been called. Failing.");
      }

      groupArray.push("updateable");
      this.height = height - wiggle * 2;
      this.width = width - wiggle * 2;
      this.initialSize = new Vec(this.height, this.width);
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
    }

    private function getChildrenOf(mc:MovieClip):Array {
      var children:Array = [];

      for (var i:int = 0; i < mc.numChildren; i++) {
        children[i] = mc.getChildAt(i);
      }

      return children;
    }

    //TODO: there is some duplication here.
    public function fromExternalMC(mcClass:*, fixedSize:Boolean = false):Entity {
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

      // If this is the container, than the difference between our childrenContainer and our mc
      // is moot. We could require the user to make 2 MCs, but that seems a bit silly,
      // especially since the container object
      if (!Fathom.container) {
        this.childrenContainer = this.mc;
      }

      return this;
    }

    public function set visible(v:Boolean):void { mc.visible = v; }
    public function get visible():Boolean { return mc.visible; }

    public function set alpha(v:Number):void { mc.alpha = v; }
    public function get alpha():Number { return mc.alpha; }

    public override function set x(v:Number):void {
      mc.x = Math.floor(v + mcOffset.x);
      _x = v;
    }
    public override function get x():Number { return _x; }

    public override function set y(v:Number):void {
      mc.y = Math.floor(v + mcOffset.y);
      _y = v;
    }

    public override function get y():Number { return _y; }

    public function set scaleX(v:Number):void { mc.scaleX = v; }
    public function get scaleX():Number { return mc.scaleX; }

    public function set scaleY(v:Number):void { mc.scaleY = v; }
    public function get scaleY():Number { return mc.scaleY; }

    public function set rotation(v:Number):void { mc.rotation = v; }
    public function get rotation():Number { return mc.rotation; }

    public function gotoAndStop(f:int):void { mc.gotoAndStop(f); }
    public function gotoAndPlay(f:int):void { mc.gotoAndPlay(f); }

    public function get totalFrames():int { return mc.totalFrames; }

    //public function set currentFrame(v:int):void { mc.gotoAndStop(v); }
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

    // Chainable methods.
    //
    // Often you'll want a lightweight custom Entity without wanting to
    // code up an entirely new class that extends. Chainable methods are
    // for you. If I want to make an explosion that quickly disappears,
    // for instance, I can do something like this:
    //
    // new Entity().fromExternalMC("Explosion").ignoreCollisions().disappearAfter(20);

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

    public function ignoreCollisions():Entity {
      _ignoresCollisions = true;

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
      Util.assert(!children.contains(child));

      children.push(child);
      child.parent = this;

      this.childrenContainer.addChild(child.mc);
      this.childrenContainer.addChild(child.childrenContainer);
    }

    // Remove child: The child entity does not belong to this entity as a child.
    // It continues to exist in the game.
    public function removeChild(child:Entity):void {
      children.remove(child);

      this.childrenContainer.removeChild(child.mc);
      this.childrenContainer.removeChild(child.childrenContainer);
    }

    /*
    public function addEvent(event:Function):Entity {
      on("post-update", event);
    }
    */

    //TODO: I don't think I like this interface.
    public function on(event:String, callback:Function):Entity {
      var prevEvents:Array = events[event] || [];

      if (! (callback in prevEvents)) {
        prevEvents.push(callback);
      }

      events[event] = prevEvents;

      return this;
    }

    public function off(event:String, callback:Function = null):Entity {
      if (!events[event]) {
        throw "Don't have that event!";
      }

      if (callback != null) {
        events[event].remove(callback);
      } else {
        events[event] = [];
      }

      return this;
    }

    public function listen(callback:Function = null):Entity {
      on("pre-update", callback);

      return this;
    }

    public function emit(event:String):Entity {
      if (event in events) {
        var hooks:Array = events[event];

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
    public function removeFromFathom(recursing:Boolean = false):void {
      for (var i:int = 0; i < children.length; i++){
        children[i].removeFromFathom(true);
      }

      if (!recursing && this.parent) this.parent.removeChild(this);

      Fathom.entities.remove(this);
      hidden = true;
    }

    /* This causes the Entity to exist in the game. There is no need to call
       this except after a call to removeFromFathom(). */
    public function addToFathom(recursing:Boolean = false):void {
      Util.assert(!destroyed);

      for (var i:int = 0; i < children.length; i++){
        children[i].addToFathom(true);
      }

      if (!recursing && this.parent) this.parent.addChild(this);

      Fathom.entities.add(this);
      hidden = false;
    }

    /* This permanently removes an Entity. It can't be add()ed back. */
    public function destroy():void {
      for (var i:int = 0; i < children.length; i++){
        children[i].destroy();
      }

      destroyed = true;
    }

    //TODO: Does not entirely clear memory.
    public function clearMemory():void {
      removeFromFathom();

      events = null;
      if (mc && mc.parent) {
        mc.parent.removeChild(mc);
      }

      mc = null;
      destroyed = true;
      Fathom.entities.remove(this);
    }

    public function addGroups(...args):Entity {
      for (var i:int = 0; i < args.length; i++) {
        groupArray.push(args[i]);
      }

      return this;
    }

    //TODO: Could add all superclasses.
    //TODO: "updateable" is the norm. "noupdate" should be a group.
    //TODO: There is a possible namespace collision here. Should prob make it impossible to manually add groups.
    //TODO: I've decided I don't like strings. Enumerations are better.
    public function groups():Array {
      return groupArray.concat(Util.className(this));
    }

    public function collides(other:Entity):Boolean {
      return !_ignoresCollisions && (!(this == other)) && touchingRect(other);
    }

    public function collidesPt(point:Point):Boolean { return mc.hitTestPoint(point.x, point.y); }

    public function update(e:EntityList):void {}

    public override function toString():String {
      return "[" + Util.className(this) + super.toString() + " (" + groups() + ") ]";
    }

    public function depth():int { return 0; }
  }
}
