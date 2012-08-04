package {
  import flash.display.Sprite;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import mx.core.BitmapAsset;
  import flash.display.BitmapData;
  import flash.display.Stage;

  public class Camera extends Rect {
    public function Camera(stage:Stage) {
      super(0, 0, stage.stageWidth, stage.stageHeight);
    }

    public function setLocation(loc:Vec):void {
      x = loc.x - width  / (2 * Fathom.scaleX);
      y = loc.y - height / (2 * Fathom.scaleY);
    }

    public function get offsetX():int {
      return x;
    }

    public function get offsetY():int {
      return y;
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
