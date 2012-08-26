package {
  import flash.display.MovieClip;
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

  public class Entity extends Rect {
    private var events:Object = {};
    // This indicates that the object should be destroyed.
    // The update loop in Fathom will eventually destroy it.
    public var destroyed:Boolean = false;
    public var hidden:Boolean = false;

    protected var mySpritesheet:Array = []

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
    protected var _mc:MovieClip;
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

    public function get mc():MovieClip { return _mc; }

    function Entity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, wiggle:int = 0):void {
      if (height == -1) height = width;

      super(x, y, this.width);

      if (!Fathom.initialized) {
        throw new Error("Util.initialize() has not been called. Failing.");
      }

      this.height = height - wiggle * 2;
      this.width = width - wiggle * 2;
      this.initialSize = new Vec(this.height, this.width);
      this.color = color;
      this.setMCOffset(0, 0);
      this.parent = null;

      this._mc = new MovieClip();

      //TODO: I had this idea about how parents should bubble down events to children.
      if (Fathom.container) {
        Fathom.entities.add(this);
      }
    }

    public function withDepth(d:int):Entity {
      _depth = d;

      return this;
    }

    public function addDropShadow():void {
      _mc.filters = [new DropShadowFilter()];
    }

    public function clearFilters():void {
      _mc.filters = [];
    }

    private function getChildrenOf(mc:MovieClip):Array {
      var children:Array = [];

      for (var i:int = 0; i < mc.numChildren; i++) {
        children[i] = mc.getChildAt(i);
      }

      return children;
    }

    public function removeMC():Entity {
      Fathom.container.addChild(this);
      this._mc.visible = false;

      return this;
    }

    private static var cachedAssets:Dictionary = new Dictionary();

    //TODO: explain the diff between these 2.
    public function updateExternalMC(mcClass:*, fixedSize:Boolean = false, spritesheet:Array = null, middleX:Boolean = false):Entity {
      var bAsset:BitmapAsset;

      var count:int = 0;

      bAsset = new mcClass(); //cachedAssets[mcClass]

      // remove all children.
      while(_mc && _mc.numChildren != 0) {
        mc.removeChildAt(0);
      }

      if (!this._mc) {
        this._mc = new MovieClip();
      }

      if (spritesheet != null) {
        var uid:String = Util.className(mcClass) + spritesheet;
        var subimage:Bitmap = new Bitmap();

        if (!(cachedAssets[uid])) {
          var bd:BitmapData = new BitmapData(C.size, C.size, true, 0);
          //subimage = new Bitmap(bd);
          var source:Rectangle = new Rectangle(spritesheet[0] * C.size, spritesheet[1] * C.size, C.size, C.size);

          bd.copyPixels(bAsset.bitmapData, source, new Point(0, 0), null, null, true);

          this.mySpritesheet = spritesheet;

          cachedAssets[uid] = bd;
        }

        subimage.bitmapData = cachedAssets[uid];

        this._mc.addChild(subimage);

        //TODO another huge hax
        if (middleX) {
          subimage.x -= 12;
        }
      } else {
        this._mc.addChild(bAsset);
      }

      return this;

    }

    // TODO seems like you need to call this function before anything is visible, even children.
    public function fromExternalMC(mcClass:*, fixedSize:Boolean = false, spritesheet:Array = null, middleX:Boolean = false):Entity {
      this.usesExternalMC = true;

      var className:String = Util.className(mcClass);

      if (className == "String") {
        this._mc = new Fathom.MCPool[mcClass]();
        groupArray.push(mcClass);
      } else if (className == "MovieClip") {
        this._mc = mcClass;
      } else {
        updateExternalMC(mcClass, fixedSize, spritesheet, middleX);
      }

      if (fixedSize) {
        _mc.width = this.width + wiggle * 2;
        _mc.height = this.height + wiggle * 2;
      }

      this.initialScaleX = _mc.scaleX;
      this.initialScaleY = _mc.scaleY;

      this._scaleX = this.initialScaleX;
      this._scaleY = this.initialScaleY;

      // All Entities are added to the container, except the container itself, which
      // has to be bootstrapped onto the Stage. If Fathom.container does not exist, `this`
      // must be the container.
      if (Fathom.container) {
        Fathom.container.addChild(this);
      }

      // If this is the container, than there is no difference between our childrenContainer and our mc.
      // We could require the user to make 2 MCs, but that seems a bit silly,
      // especially since the container object will never be anything other than a contaienr.
      if (!Fathom.container) {
        this.childrenContainer = this._mc;
      }

      return this;
    }

    public override function set(v:IPositionable):Vec {
      x = v.x;
      y = v.y;

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

    public override function get y():Number { return _y; }

    public override function set y(v:Number):void {
      mc.y = Math.floor(v + mcOffset.y);
      _y = v;
    }

    public function get cameraSpaceX():Number {
      return Math.floor(_x + mcOffset.x);
    }

    public function get cameraSpaceY():Number {
      return Math.floor(_y + mcOffset.y);
    }

    // These functions are in Entity space.
    public function set scaleX(v:Number):void { _scaleX = v * initialScaleX; }
    public function get scaleX():Number { return _scaleX / initialScaleX; }

    public function set scaleY(v:Number):void { _scaleY = v * initialScaleY; }
    public function get scaleY():Number { return _scaleY / initialScaleY; }

    // These two are in Camera space.
    public function get cameraSpaceScaleX():Number { return _scaleX; }
    public function get cameraSpaceScaleY():Number { return _scaleY; }

    public function set rotation(v:Number):void { _mc.rotation = v; }
    public function get rotation():Number { return _mc.rotation; }

    public function gotoAndStop(f:int):void { _mc.gotoAndStop(f); }
    public function gotoAndPlay(f:int):void { _mc.gotoAndPlay(f); }

    public function get totalFrames():int { return _mc.totalFrames; }

    //public function set currentFrame(v:int):void { mc.gotoAndStop(v); }
    public function get currentFrame():int { return _mc.currentFrame; }

    public function play():void { _mc.play(); }

    protected function setMCOffset(x:int, y:int):void {
      this.mcOffset = (new Vec(wiggle, wiggle)).add(new Vec(x, y));
    }

    // Pass in the x-coordinate of your velocity, and this'll orient
    // the Entity in that direction.
    protected function face(dir:int):void {
      if (dir > 0 && this._mc.scaleX < 0) {
        this._mc.scaleX *= -1;
        return;
      }
      if (dir < 0 && this._mc.scaleX > 0) {
        this._mc.scaleX *= -1;
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
      if (this._mc.parent) {
        this._mc.parent.setChildIndex(this._mc, this._mc.parent.numChildren - 1);
      }
    }

    //TODO: addChild is basically TOTALLY screwed up w/r/t depth. RGHRKGJHSDKLJF

    public function addChild(child:Entity):void {
      Util.assert(!children.contains(child));

      children.push(child);
      child.parent = this;

      this.childrenContainer.addChild(child._mc);
      this.childrenContainer.addChild(child.childrenContainer);
    }

    // Remove child: The child entity does not belong to this entity as a child.
    // It continues to exist in the game.
    public function removeChild(child:Entity):void {
      children.remove(child);

      this.childrenContainer.removeChild(child._mc);
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
      if (_mc && _mc.parent) {
        _mc.parent.removeChild(_mc);
      }

      _mc = null;
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
      mc.x = loc.x;
      mc.y = loc.y;

      childrenContainer.x = loc.x;
      childrenContainer.y = loc.y;
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

    public function collidesPt(point:Point):Boolean { return _mc.hitTestPoint(point.x, point.y); }

    public function update(e:EntityList):void {}

    public override function toString():String {
      return "[" + Util.className(this) + super.toString() + " (" + groups() + ") ]";
    }

    public function depth():int {
      return _depth;
    }

    // Modes for which this entity receives events.
    public function modes():Array { return [0]; }
  }
}
