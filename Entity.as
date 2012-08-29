package {
  import flash.display.Sprite;
  import flash.display.DisplayObject;
  import flash.filters.DropShadowFilter;
  import flash.geom.Point;
  import flash.utils.getQualifiedClassName;
  import flash.debugger.enterDebugger;
  import mx.core.BitmapAsset;
  import flash.utils.Dictionary;
  import flash.display.BitmapData;

  import flash.display.Bitmap;
  import flash.geom.Rectangle;

  import Hooks;
  import Util;
  import MagicArray;

  public class Entity extends Sprite implements IPositionable {
    private var events:Object = {};

    // This indicates that the object should be destroyed.
    // The update loop in Fathom will eventually destroy it.
    public var destroyed:Boolean = false;
    public var hidden:Boolean = false;

    private static var cachedAssets:Dictionary = new Dictionary();

    protected var spritesheet:Array = []

    protected var initialScaleX:Number = 1.0;
    protected var initialScaleY:Number = 1.0;

    protected var _scaleX:Number = 1.0;
    protected var _scaleY:Number = 1.0;

    protected var groupArray:Array = ["updateable", "persistent"];
    protected var color:Number;
    protected var children:Array = [];
    protected var wiggle:int = 0;
    protected var usesExternalMC:Boolean = false;
    protected var _ignoresCollisions:Boolean = false;

    protected var _depth:int = 0;

    protected var mcOffset:Vec;
    protected var initialSize:Vec;


    // The location of the entity, before camera transformations.
    private var entitySpacePos:Rect;

    // The location of the entity, after camera transformations.
    public var pos:Rect;

    // Allows for a fast check to see if this entity moves.
    protected var _isStatic:Boolean = true;

    public function get isStatic():Boolean { return _isStatic; }
    private function set isStatic(val:Boolean):void { _isStatic = val; }

    public function get childrenList():Array { return children; }

    function Entity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, wiggle:int = 0):void {
      if (height == -1) height = width;

      if (!Fathom.initialized) {
        throw new Error("Util.initialize() has not been called. Failing.");
      }

      this.pos = new Rect(x, y, width, height);
      this.entitySpacePos = new Rect(x, y, width, height);

      this.x = x;
      this.y = y;
      this.height = height - wiggle * 2;
      this.width = width - wiggle * 2;
      this.initialSize = new Vec(this.height, this.width);
      this.color = color;
      this.setMCOffset(0, 0);

      //TODO: I had this idea about how parents should bubble down events to children.
      if (Fathom.container) {
        Fathom.entities.add(this);
      }

      // All Entities are added to the container, except the container itself, which
      // has to be bootstrapped onto the Stage. If Fathom.container does not exist, `this`
      // must be the container.
    }

    /*
    public function set absX(val:Number):void {
      //bla bla bla local2Global TODO
    }
    */

    public override function set x(val:Number):void {
      entitySpacePos.x = val;
    }

    public override function get x():Number {
      return entitySpacePos.x;
    }

    public override function set y(val:Number):void {
      entitySpacePos.y = val;
    }

    public override function get y():Number {
      return entitySpacePos.y;
    }



    public function set cameraSpaceX(val:Number):void {
      pos.x = val;
    }

    public function get cameraSpaceX():Number {
      //return Math.floor(x + mcOffset.x);
      return pos.x;
    }

    public function set cameraSpaceY(val:Number):void {
      entitySpacePos.y = val;
    }

    public function get cameraSpaceY():Number {
      //return Math.floor(y + mcOffset.y);
      return pos.y;
    }


    public override function set width(val:Number):void {
      entitySpacePos.width = val;
    }

    public override function get width():Number {
      return entitySpacePos.width;
    }

    public override function set height(val:Number):void {
      entitySpacePos.height = val;
    }

    public override function get height():Number {
      return entitySpacePos.height;
    }

    public function rect():Rect {
      return pos;
    }

    public function withDepth(d:int):Entity {
      _depth = d;

      return this;
    }

    private function getChildrenOf(mc:Sprite):Array {
      var children:Array = [];

      for (var i:int = 0; i < mc.numChildren; i++) {
        children[i] = mc.getChildAt(i);
      }

      return children;
    }

    public function removeMC():Entity {
      Fathom.container.addChild(this);
      this.visible = false;

      return this;
    }

    //TODO: explain the diff between these 2.
    public function updateExternalMC(mcClass:*, fixedSize:Boolean = false, spritesheet:Array = null, middleX:Boolean = false):Entity {
      var bAsset:BitmapAsset;

      var count:int = 0;

      bAsset = new mcClass(); //cachedAssets[mcClass]

      // remove all children.
      while(numChildren != 0) {
        removeChildAt(0);
      }

      if (spritesheet != null) {
        var uid:String = Util.className(mcClass) + spritesheet;
        var subimage:Bitmap = new Bitmap();

        if (!(cachedAssets[uid])) {
          var bd:BitmapData = new BitmapData(C.size, C.size, true, 0);
          var source:Rectangle = new Rectangle(spritesheet[0] * C.size, spritesheet[1] * C.size, C.size, C.size);

          bd.copyPixels(bAsset.bitmapData, source, new Point(0, 0), null, null, true);

          cachedAssets[uid] = bd;
        }

        this.spritesheet = spritesheet;
        subimage.bitmapData = cachedAssets[uid];

        this.addChild(subimage);

        //TODO another huge hax
        if (middleX) {
          subimage.x -= 12;
        }
      } else {
        this.addChild(bAsset);
      }

      return this;

    }

    // TODO seems like you need to call this function before anything is visible, even children.
    public function fromExternalMC(mcClass:*, fixedSize:Boolean = false, spritesheet:Array = null, middleX:Boolean = false):Entity {
      this.usesExternalMC = true;

      var className:String = Util.className(mcClass);

      // TODO: All of this crap is going to break. Can't reassign to this.
      if (className == "String") {
        // Use a movieclip from the provided MovieClip pool. Handy for including vector graphics.
        //this._mc = new Fathom.MCPool[mcClass]();
        //groupArray.push(mcClass);
        Util.assert(false);
      } else if (className == "Sprite" || className == "MovieClip") {
        Util.assert(false);
        //this._mc = mcClass;
      } else {
        updateExternalMC(mcClass, fixedSize, spritesheet, middleX);
      }

      if (fixedSize) {
        width  = this.width  + wiggle * 2;
        height = this.height + wiggle * 2;
      }

      // TODO don't like this at all.

      initialScaleX = scaleX;
      initialScaleY = scaleY;

      return this;
    }

    public function set(v:IPositionable):Entity {
      x = v.x;
      y = v.y;

      return this;
    }

    // These functions are in Entity space.
    //public override function set scaleX(v:Number):void { scaleX = v * initialScaleX; }
    //public override function get scaleX():Number { return scaleX / initialScaleX; }

    //public override function set scaleY(v:Number):void { scaleY = v * initialScaleY; }
    //public override function get scaleY():Number { return scaleY / initialScaleY; }

    // These two are in Camera space.
    public function get cameraSpaceScaleX():Number { return scaleX; }
    public function get cameraSpaceScaleY():Number { return scaleY; }

    protected function setMCOffset(x:int, y:int):void {
      this.mcOffset = (new Vec(wiggle, wiggle)).add(new Vec(x, y));
    }

    // Pass in the x-coordinate of your velocity, and this'll orient
    // the Entity in that direction.
    protected function face(dir:int):void {
      if (dir > 0 && this.scaleX < 0) {
        this.scaleX *= -1;
        return;
      }
      if (dir < 0 && this.scaleX > 0) {
        this.scaleX *= -1;
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
      if (this.parent) {
        this.parent.setChildIndex(this, this.parent.numChildren - 1);
      }
    }

    //TODO: addChild is basically TOTALLY screwed up w/r/t depth. RGHRKGJHSDKLJF

    public override function addChild(child:DisplayObject):DisplayObject {
      Util.assert(!children.contains(child));

      if (child is Entity) {
        children.push(child);
      }

      super.addChild(child);

      return child;
    }

    // Remove child: The child entity does not belong to this entity as a child.
    // It continues to exist in the game.
    public override function removeChild(child:DisplayObject):DisplayObject {
      if (children.contains(child)) {
        children.remove(child);
      }

      super.removeChild(child);

      return child;
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

    public function currentlyBlocking(...args):EntityList {
      return currentlyTouching.apply(this, args.concat("!non-blocking"));
    }

    /* This causes the Entity to cease existing in-game. The only way to
       bring it back is to call addToFathom(). */
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
      if (parent) {
        parent.removeChild(this);
      }

      destroyed = true;
      Fathom.entities.remove(this);
    }

    public function addGroups(...args):Entity {
      for (var i:int = 0; i < args.length; i++) {
        groupArray.push(args[i]);
      }

      return this;
    }

    public function setAbsolutePosition(loc:Vec):void {
      x = loc.x;
      y = loc.y;
    }

    //TODO: Group strings to enums with Inheritable property.
    //TODO: "updateable" is the norm. "noupdate" should be a group.
    //TODO: There is a possible namespace collision here. Should prob make it impossible to manually add groups.
    //TODO: I've decided I don't like strings. Enumerations are better.
    public function groups():Array {
      return groupArray.concat(Util.className(this));
    }

    public function touchingRect(rect:Entity):Boolean {
      return !   (rect.x      > this.x + this.width  ||
         rect.x + rect.width  < this.x               ||
         rect.y               > this.y + this.height ||
         rect.y + rect.height < this.y               );
    }

    public function collides(other:Entity):Boolean {
      return !_ignoresCollisions && (!(this == other)) && touchingRect(other);
    }

    public function collidesPt(point:Point):Boolean { return hitTestPoint(point.x, point.y); }

    public function update(e:EntityList):void {}

    public override function toString():String {
      return "[" + Util.className(this) + super.toString() + " (" + groups() + ") ]";
    }

    public function set depth(v:int):void {
      _depth = v;
    }

    public function get depth():int {
      return _depth;
    }

    public function add(p:IPositionable):Entity {
      this.x += p.x;
      this.y += p.y;

      return this;
    }

    // Modes for which this entity receives events.
    public function modes():Array { return [0]; }
  }
}
