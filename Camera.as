package {
  import flash.display.Sprite;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import mx.core.BitmapAsset;
  import flash.display.BitmapData;
  import flash.display.Stage;

  public class Camera extends Rect {
    private var CAM_LAG:int = 90;

    // This is the rect that the camera will always stay inside.
    private var _boundingRect:Rect = null;

    //TODO this is more trouble than it's worth.
    // This is the rect the *focal point* will always stay inside.
    private var innerBoundingRect:Rect = null;

    // This is an array of all events currently happening to this camera.
    private var events:Array = [];

    // These two variables are the focal points of the camera.
    private var _focalX:Number;
    private var _focalY:Number;

    // If our camera lags behing the player, this is where it will eventually want to be.
    private var goalFocalX:Number;
    private var goalFocalY:Number;

    // If the camera is normalWidth by normalHeight, then no MovieClips will have to be scaled.
    private var normalWidth:Number;
    private var normalHeight:Number;

    // These dimensions are the default scaled width of the camera. The camera may temporarily adjust
    // itself out of these dimensions, if, say, it's told to keepInScene() an Entity
    // that wandered out of the Camera bounds.
    private var scaledWidth:Number;
    private var scaledHeight:Number;

    private var FOLLOW_MODE_NONE:int = 0;
    private var FOLLOW_MODE_SLIDE:int = 1;

    private var followMode:int = FOLLOW_MODE_SLIDE;

    // The Rect we extend from is the area from the game the camera displays.

    // TODO: This camera does not at all take into consideration non-square
    // dimensions. That would make life a bit harder.

    public function Camera(stage:Stage) {
      super(0, 0, stage.stageWidth / Fathom.scaleX, stage.stageHeight / Fathom.scaleY);

      this.normalWidth  = this.width;
      this.normalHeight = this.height;

      this.scaledWidth = this.width;
      this.scaledHeight = this.height;
    }

    public function scaleBy(val:Number):Camera {
      this.width = this.normalWidth * val;
      this.height = this.normalHeight * val;

      this.scaledWidth = this.width;
      this.scaledHeight = this.height;

      if (innerBoundingRect) {
        innerBoundingRect.x *= val;
        innerBoundingRect.y *= val;

        innerBoundingRect.width *= val;
        innerBoundingRect.height *= val;
      }

      return this;
    }

    public function bind(val:Number, low:Number, high:Number):Number {
      if (val < low) return low;
      if (val > high) return high;

      return val;
    }

    public function isBound() {
      return innerBoundingRect != null;
    }

    // Updating the focus updates the x, y coordinates also, and vice versa.

    public function set focalX(val:Number):void {
      _focalX = isBound() ? bind(val, innerBoundingRect.x, innerBoundingRect.right) : val;

      _x = _focalX - width  / 2;
    }

    public function set focalY(val:Number):void {
      _focalY = isBound() ? bind(val, innerBoundingRect.y, innerBoundingRect.bottom) : val;

      _y = _focalY - height / 2;
    }

    public override function set x(val:Number):void {
      var newFocusX = x + width / 2;

      _focalX = isBound() ? bind(newFocusX, innerBoundingRect.x, innerBoundingRect.right) : val;

      _x = _focalX - width / 2;
    }

    public override function set y(val:Number):void {
      var newFocusY = y + height / 2;

      _focalY = isBound() ? bind(newFocusY, innerBoundingRect.y, innerBoundingRect.bottom) : val;

      _y = _focalY - width / 2;
    }

    public override function set width(val:Number):void {
      var newFocusX = x + val / 2;

      _focalX = isBound() ? bind(newFocusX, innerBoundingRect.x, innerBoundingRect.right) : val;
      _width = val;

      calculateInnerBoundRect();
    }

    public override function set height(val:Number):void {
      var newFocusY = y + val / 2;

      _focalY = isBound() ? bind(newFocusY, innerBoundingRect.y, innerBoundingRect.bottom) : val;
      _height = val;

      calculateInnerBoundRect();
    }

    public function beBoundedBy(m:Map):Camera {
      this.boundingRect = new Rect(0, 0, m.sizeVector.x, m.sizeVector.y);

      return this;
    }

    // Set the bounding rectangle that the camera can't move outside of.
    // We reduce the size so that we can compare the center coordinate of the
    // camera to see if it's in bounds.
    public function set boundingRect(val:Rect):void {
      _boundingRect = val;

      calculateInnerBoundRect();
    }

    private function calculateInnerBoundRect():void {
      if (!_boundingRect) return;

      innerBoundingRect = new Rect( _boundingRect.x + this.width / 2
                                  , _boundingRect.y + this.height / 2
                                  , _boundingRect.width - this.width
                                  , _boundingRect.height - this.height);
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

    /* Shake the camera for duration ticks, up to range pixels
     * away from where it started */
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
        if (Math.abs(goalFocalX - _focalX) > .0000001) {
          focalX = _focalX + (goalFocalX - _focalX) / CAM_LAG;
        } else {
          focalX = goalFocalX;
        }

        if (Math.abs(goalFocalY - _focalY) > .0000001) {
          focalY = _focalY + (goalFocalY - _focalY) / CAM_LAG;
        } else {
          focalY = goalFocalY;
        }

        return;
      }

      if (followMode == FOLLOW_MODE_NONE) {
        focalX = goalFocalX;
        focalY = goalFocalY;

        return;
      }

      throw new Error("Invalid Camera mode: " + followMode);
    }

    /* Adjust camera such that the entity e is in the scene. */
    public function keepInScene(e:Entity):void {
      var resized:Boolean = false;

      if (e.x >= x || e.y >= y) {
        // newSize is in Entity Space, as is scaledWidth.
        var newSize:Number = Math.max(e.x - x, e.y - y);

        if (newSize > scaledWidth) {
          width = newSize;
          height = newSize;

          resized = true;
        }
      }

      if (!resized) {
        width = scaledWidth;
        height = scaledHeight;
      } else {
        trace ("RESIZE");
      }
    }

    // TODO: mcX properties are sloppy.
    public function update():void {
      var that:Camera = this;

      for (var i:int = 0; i < events.length; i++) {
        events[i]();
      }

      updateXY();

      var camScaleX:Number = normalWidth / width;
      var camScaleY:Number = normalHeight / height;

      Fathom.entities.get("!no-camera").each(function(e:Entity):void {
        e.mc.x = (e.mcX - that.x) * camScaleX;
        e.mc.y = (e.mcY - that.y) * camScaleY;

        if (e.scaleX != camScaleX) e.scaleX = Util.sign(e.scaleX) * camScaleX;
        if (e.scaleY != camScaleY) e.scaleY = Util.sign(e.scaleY) * camScaleY;
      });

      Fathom.entities.get("no-camera").each(function(e:Entity):void {
        e.setAbsolutePosition(that);
      });
    }
  }
}
