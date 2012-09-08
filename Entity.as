package {
  import flash.display.Sprite;
  import flash.display.DisplayObject;
  import flash.display.DisplayObjectContainer;
  import flash.filters.DropShadowFilter;
  import flash.geom.Point;
  import flash.utils.getQualifiedClassName;
  import flash.debugger.enterDebugger;
  import mx.core.BitmapAsset;
  import flash.utils.Dictionary;
  import flash.display.BitmapData;

  import flash.display.Bitmap;
  import flash.geom.Rectangle;
  import flash.geom.Matrix;

  import Hooks;
  import Util;
  import MagicArray;

  public class Entity extends Sprite implements IPositionable {
    private var events:Object = {};

    // This indicates that the object should be destroyed.
    // The update loop in Fathom will eventually destroy it.
    public var destroyed:Boolean = false;

    private static var cachedAssets:Dictionary = new Dictionary();

    // Rename spritesheetObj and spritesheet
    // spritesheetObj isnt even necessarily a spritesheet
    private var spritesheetObj:* = null;
    private var tileDimension:Vec;

    protected var pixels:Bitmap = new Bitmap();
    protected var spritesheet:Array = []
    protected var groupArray:Array = ["persistent"];
    protected var entityChildren:Array = [];
    protected var _ignoresCollisions:Boolean = false;
    protected var _depth:int = 0;

    // These is purely for debugging purposes.
    protected static var counter:int = 0;
    protected var uid:Number = ++counter;

    protected var rememberedParent:DisplayObjectContainer;

    // The location of the entity, before camera transformations.
    private var entitySpacePos:Rect;

    // The location of the entity, after camera transformations.
    public var cameraSpacePos:Rect;

    // Allows for a fast check to see if this entity moves.
    protected var _isStatic:Boolean = true;

    public function get isStatic():Boolean { return _isStatic; }
    private function set isStatic(val:Boolean):void { _isStatic = val; }

    function Entity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1):void {
      if (height == -1) height = width;

      if (!Fathom.initialized) {
        throw new Error("Util.initialize() has not been called. Failing.");
      }

      this.cameraSpacePos = new Rect(0, 0, width, height);
      this.entitySpacePos = new Rect(x, y, width, height);

      this.x = x;
      this.y = y;
      this.height = height;
      this.width = width;

      //TODO: I had this idea about how parents should bubble down events to children.

      // All Entities are added to the container, except the container itself, which
      // has to be bootstrapped onto the Stage. If Fathom.container does not exist, `this`
      // must be the container.

      if (Fathom.container) {
        this.rememberedParent = Fathom.container;
        addToFathom();
      }

      // Bypass our overridden addChild method.
      super.addChild(pixels);
   }

    public function get absX():Number {
      var p:DisplayObjectContainer = this;
      var result:int = 0;

      while (p != null) {
        result += p.x;

        p = p.parent;
      }

      return result;
    }

    public function get absY():Number {
      var p:DisplayObjectContainer = this;
      var result:int = 0;

      while (p != null) {
        result += p.y;

        p = p.parent;
      }

      return result;
    }

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
      cameraSpacePos.x = val;
      super.x = cameraSpacePos.x;
    }

    public function get cameraSpaceX():Number {
      return cameraSpacePos.x;
    }

    public function set cameraSpaceY(val:Number):void {
      cameraSpacePos.y = val;
      super.y = cameraSpacePos.y
    }

    public function get cameraSpaceY():Number {
      return cameraSpacePos.y;
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
      return new Rect(entitySpacePos.x, entitySpacePos.y, width, height);
    }

    public function vec():Vec {
      return new Vec(entitySpacePos.x, entitySpacePos.y);
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

    // Set this entities graphics to be the sprite at (x, y) on the provided spritesheet.
    public function setTile(x:int, y:int):Entity {
      Util.assert(this.spritesheetObj != null);

      //TODO: Cache this
      var bAsset:BitmapAsset = spritesheetObj;

      var count:int = 0;

      Util.assert(entityChildren.length == 0);

      var uid:String = Util.className(spritesheetObj) + x + " " + y;
      if (!(cachedAssets[uid])) {
        var bd:BitmapData = new BitmapData(width, height, true, 0);
        var source:Rectangle = new Rectangle(x * width, y * height, width, height);

        bd.copyPixels(bAsset.bitmapData, source, new Point(0, 0), null, null, true);

        cachedAssets[uid] = bd;
      }

      this.spritesheet = spritesheet;
      pixels.bitmapData = cachedAssets[uid];

      return this;

    }

    // TODO: This could eventually be called setOrigin.
    public function setRotationOrigin(x:Number, y:Number):Entity {
      pixels.x -= x;
      pixels.y -= y;

      return this;
    }

    //TODO: Maybe shouldn't even have to pass in tileDimension.

    /* Load a spritesheet. tileDimension should be the size of the tiles; pass in null if
       there's only one tile. whichTile is the tile that this Entity will be; pass in
       null if you want to defer the decision by calling setTile() later. */
    public function loadSpritesheet(spritesheetClass:*, tileDimension:Vec = null, whichTile:Vec = null):Entity {
      Util.assert(this.spritesheetObj == null);

      this.spritesheetObj = new spritesheetClass();

      var spritesheetSize:Vec = new Vec(spritesheetObj.width, spritesheetObj.height)

      if (tileDimension != null) {
        this.width = tileDimension.x;
        this.height = tileDimension.y;
      } else {
        this.width = spritesheetObj.width;
        this.height = spritesheetObj.height;
      }

      if (whichTile != null) {
        setTile(whichTile.x, whichTile.y)
      } else {
        setTile(0, 0);
      }

      return this;
    }

    public function loadImage(imgClass:*):Entity {
      Util.assert(this.spritesheetObj == null);

      this.spritesheetObj = new imgClass();

      this.tileDimension = new Vec(spritesheetObj.width, spritesheetObj.height)

      setTile(0, 0);

      return this;
    }

    public function setPos(v:IPositionable):Entity {
      x = v.x;
      y = v.y;

      return this;
    }

    public function flipBitmapData(original:BitmapData, axis:String = "x"):BitmapData {
      var flipped:BitmapData = new BitmapData(original.width, original.height, true, 0);
      var matrix:Matrix
      if(axis == "x") {
          matrix = new Matrix( -1, 0, 0, 1, original.width, 0);
      } else {
          matrix = new Matrix( 1, 0, 0, -1, 0, original.height);
      }
      flipped.draw(original, matrix, null, null, null, true);
      return flipped;
    }

    // These two are in Camera space.
    public function get cameraSpaceScaleX():Number { return scaleX; }
    public function get cameraSpaceScaleY():Number { return scaleY; }

    protected var facing:int = 1;

    // Pass in the x-coordinate of your velocity, and this'll orient
    // the Entity in that direction.
    protected function face(dir:int):void {
      if (dir > 0 && facing < 0) {
        pixels.bitmapData = flipBitmapData(pixels.bitmapData)
        facing = dir;
        return;
      }
      if (dir < 0 && facing > 0) {
        pixels.bitmapData = flipBitmapData(pixels.bitmapData)
        facing = dir;
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

    public function debugDraw():Entity {
      graphics.beginFill(0xFF0000);
      graphics.drawRect(0, 0, this.width, this.height);
      graphics.endFill();

      return this;
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

    public function ignoreCollisions():Entity {
      _ignoresCollisions = true;

      return this;
    }

    public function raiseToTop():void {
      if (this.parent) {
        this.parent.setChildIndex(this, this.parent.numChildren - 1);
      }
    }

    /* Put this entity in the middle of the screen. Useful for dialogs,
       inventory screens, etc. */
    public function centerOnScreen():void {
      x = Fathom.stage.width / 2 - this.width / 2;
      y = Fathom.stage.height / 2 - this.height / 2;
    }

    public override function addChild(child:DisplayObject):DisplayObject {
      Util.assert(!entityChildren.contains(child));

      super.addChild(child);

      if (child is Entity) {
        entityChildren.push(child);
      }

      return child;
    }

    // Remove child: The child entity does not belong to this entity as a child.
    // It continues to exist in the game.
    public override function removeChild(child:DisplayObject):DisplayObject {
      Util.assert(entityChildren.contains(child));
      entityChildren.remove(child);

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

    public function touchingSet(...args):EntitySet {
      var that:* = this;

      // It is important that we use *their* collision method, not ours.
      // TODO: This will lead to disaster down the line (imagine colliding two maps!)

      var touchesMe:Function = function(other:Entity):Boolean {
        return other.collides(that);
      };

      return Fathom.entities.get.apply(this, args.concat(touchesMe));
    }

    public function isTouching(...args):Boolean {
      return touchingSet.apply(this, args).length > 0;
    }

    public function blockingSet(...args):EntitySet {
      return touchingSet.apply(this, args.concat("!non-blocking"));
    }

    public function isBlocked(...args):Boolean {
      return blockingSet.apply(this).length > 0;
    }

    /* This causes the Entity to cease existing in-game. The only way to
       bring it back is to call addToFathom(). */
    public function removeFromFathom(recursing:Boolean = false):void {
      Util.assert(this.parent != null);

      this.rememberedParent = this.parent;

      for (var i:int = 0; i < entityChildren.length; i++){
        entityChildren[i].removeFromFathom(true);
      }

      if (!recursing && this.parent) this.parent.removeChild(this);

      Fathom.entities.remove(this);
    }

    /* This causes the Entity to exist in the game. There is no need to call
       this except after a call to removeFromFathom(). */
    public function addToFathom(recursing:Boolean = false):void {
      Util.assert(!destroyed);
      Util.assert(!this.parent);

      for (var i:int = 0; i < entityChildren.length; i++){
        entityChildren[i].addToFathom(true);
      }

      if (!recursing) rememberedParent.addChild(this);

      Fathom.entities.add(this);

      Util.assert(rememberedParent != null);
    }

    /* This flags an Entity to be removed permanently. It can't be add()ed back. */
    public function destroy():void {
      Util.assert(Fathom.entities.contains(this));

      for (var i:int = 0; i < entityChildren.length; i++){
        entityChildren[i].destroy();
      }

      destroyed = true;
    }

    //TODO: Does not entirely clear memory.

    // If an entity is flagged for removal with destroy(), clearMemory() will eventually
    // be called on it.
    public function clearMemory():void {
      removeFromFathom();

      events = null;

      destroyed = true;
    }

    public function addGroups(...args):Entity {
      for (var i:int = 0; i < args.length; i++) {
        groupArray.push(args[i]);
      }

      return this;
    }

    public function sortDepths():void {
      entityChildren.sort(function(a:Entity, b:Entity):int {
        return a.depth - b.depth;
      });

      for (var i:int = 0; i < entityChildren.length; i++) {
        entityChildren[i].raiseToTop();
      }
    }

    //TODO: Group strings to enums with Inheritable property.
    //TODO: There is a possible namespace collision here. assert no 2 groups have same name.
    //TODO: Enumerations are better.
    public function groups():Array {
      return groupArray.concat(Util.className(this));
    }

    public function touchingRect(rect:Entity):Boolean {
      return     (rect.x      < this.x + this.width  &&
         rect.x + rect.width  > this.x               &&
         rect.y               < this.y + this.height &&
         rect.y + rect.height > this.y               );
    }

    public function collides(other:Entity):Boolean {
      return !_ignoresCollisions && (!(this == other)) && touchingRect(other);
    }

    public function collidesPt(point:Point):Boolean {
      return hitTestPoint(point.x, point.y);
    }

    public function update(e:EntitySet):void {}

    public override function toString():String {
      return "[" + Util.className(this) + " " + this.x + " " + this.y + "]"
    }

    //public override function toString():String {
    //  return "[" + Util.className(this) + super.toString() + " @" + entitySpacePos + " (" + groups() + ") " + uid + "]";
    //}

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
