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

    // These two variables are the focal points of the camera.
    private var _focalX:int;
    private var _focalY:int;

    // The Rect we extend from is the area from the game the camera displays.

    public function Camera(stage:Stage) {
      super(0, 0, stage.stageWidth, stage.stageHeight);
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

      _x = _focalX - width  / (2 * Fathom.scaleX);
    }

    public function set focalY(val:Number):void {
      _focalY = isBound() ? bind(val, _boundingRect.y, _boundingRect.bottom) : val;

      _y = _focalY - height / (2 * Fathom.scaleY);
    }

    public override function set x(val:Number):void {
      var newFocusX = x + width / (2 * Fathom.scaleX);

      _focalX = isBound() ? bind(newFocusX, _boundingRect.x, _boundingRect.right) : val;

      _x = _focalX - width / (2 * Fathom.scaleX);
    }

    public override function set y(val:Number):void {
      var newFocusY = y + height / (2 * Fathom.scaleY);

      _focalY = isBound() ? bind(newFocusY, _boundingRect.y, _boundingRect.bottom) : val;

      _y = _focalY - width / (2 * Fathom.scaleY);
    }

    // Set the bounding rectangle that the camera can't move outside of.
    // We reduce the size so that we can compare the center coordinate of the
    // camera to see if it's in bounds.
    public function set boundingRect(val:Rect):void {
      val.divide(Fathom.scaleX);

      _boundingRect = new Rect( val.x + this.width
                              , val.y + this.height
                              , val.width - this.width
                              , val.y - this.height);
    }

    // Sets the center of the Camera to look at `loc`.
    public function setFocus(loc:Vec):void {
      focalX = loc.x;
      focalY = loc.y;
    }

    // TODO: mcX properties are sloppy.
    public function update():void {
      var that:Camera = this;

      Fathom.entities.each(function(e:Entity):void {
        e.mc.x = e.mcX - that.x;
        e.mc.y = e.mcY - that.y;
      });
    }
  }
}
