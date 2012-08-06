package {
  import flash.display.Sprite;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import mx.core.BitmapAsset;
  import flash.display.BitmapData;
  import flash.display.Stage;

  public class Camera extends Rect {
    // This is the rect that the camera will always stay inside.
    private var _boundingRect:Rect = null;

    // This is an array of all events currently happening to this camera.
    private var events:Array = [];

    // These two variables are the focal points of the camera.
    private var _focalX:int;
    private var _focalY:int;

    // If our camera lags behing the player, this is where it will eventually want to be.
    private var goalFocalX:int;
    private var goalFocalY:int;

    private var normalWidth:int;
    private var normalHeight:int;

    private var FOLLOW_MODE_NONE:int = 0;
    private var FOLLOW_MODE_SLIDE:int = 1;

    private var followMode:int = FOLLOW_MODE_SLIDE;

    // The Rect we extend from is the area from the game the camera displays.

    public function Camera(stage:Stage) {
      super(0, 0, stage.stageWidth / Fathom.scaleX, stage.stageHeight / Fathom.scaleY);

      this.normalHeight = this.height;
      this.normalWidth  = this.width;

      this.width = this.normalWidth / 2;
      this.height = this.normalHeight / 2;
    }

    public function bind(val:Number, low:Number, high:Number):Number {
      if (val < low) return low;
      if (val > high) return high;

      return val;
    }

    public function isBound() {
      return _boundingRect != null;
    }

    // Updating the focus updates the x, y coordinates also, and vice versa.

    public function set focalX(val:Number):void {
      _focalX = isBound() ? bind(val, _boundingRect.x, _boundingRect.right) : val;

      _x = _focalX - width  / 2;
    }

    public function set focalY(val:Number):void {
      _focalY = isBound() ? bind(val, _boundingRect.y, _boundingRect.bottom) : val;

      _y = _focalY - height / 2;
    }

    public override function set x(val:Number):void {
      var newFocusX = x + width / 2;

      _focalX = isBound() ? bind(newFocusX, _boundingRect.x, _boundingRect.right) : val;

      _x = _focalX - width / 2;
    }

    public override function set y(val:Number):void {
      var newFocusY = y + height / 2;

      _focalY = isBound() ? bind(newFocusY, _boundingRect.y, _boundingRect.bottom) : val;

      _y = _focalY - width / 2;
    }

    public function beBoundedBy(m:Map):Camera {
      this.boundingRect = new Rect(0, 0, m.sizeVector.x, m.sizeVector.y);

      return this;
    }

    // Set the bounding rectangle that the camera can't move outside of.
    // We reduce the size so that we can compare the center coordinate of the
    // camera to see if it's in bounds.
    public function set boundingRect(val:Rect):void {
      _boundingRect = new Rect( val.x + this.width / 2
                              , val.y + this.height / 2
                              , val.width - this.width
                              , val.height - this.height);
    }

    // Sets the center of the Camera to look at `loc`.
    public function setFocus(loc:Vec):void {
      goalFocalX = loc.x;
      goalFocalY = loc.y;
    }

    /* Force the camera to go snap to the desired focal point, ignoring any
     * lag. This is expected for example when a new map is loaded.
     */

    public function snapTo(e:Entity):void {
      focalX = e.x;
      focalY = e.y;
    }

    public function shake(duration:int = 30, range:int = 5):void {
      var that:Camera = this;

      var fn = function():void {
        that.focalX = that._focalX + Util.randRange(-range, range);
        that.focalY = that._focalY + Util.randRange(-range, range);

        if (duration < 0) {
          that.events.remove(fn);
        }

        duration--;
      };

      events.push(fn);
    }

    private function updateXY():void {
      if (followMode == FOLLOW_MODE_SLIDE) {
        focalX = _focalX + (goalFocalX - _focalX) / 15;
        focalY = _focalY + (goalFocalY - _focalY) / 15;

        return;
      }

      if (followMode == FOLLOW_MODE_NONE) {
        focalX = goalFocalX;
        focalY = goalFocalY;

        return;
      }

      throw new Error("Invalid Camera mode: " + followMode);
    }

    // TODO: mcX properties are sloppy.
    public function update():void {
      var that:Camera = this;

      for (var i:int = 0; i < events.length; i++) {
        events[i]();
      }

      updateXY();

      var camScaleX:int = normalWidth / width;
      var camScaleY:int = normalHeight / height;

      Fathom.entities.get("!no-camera").each(function(e:Entity):void {
        e.mc.x = (e.mcX - that.x) * camScaleX;
        e.mc.y = (e.mcY - that.y) * camScaleY;

        if (e.scaleX != camScaleX) e.scaleX = camScaleX;
        if (e.scaleY != camScaleY) e.scaleY = camScaleY;
      });

      Fathom.entities.get("no-camera").each(function(e:Entity):void {
        e.setAbsolutePosition(that);
      });
    }
  }
}
