package {
  import flash.display.Sprite;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import mx.core.BitmapAsset;
  import flash.display.BitmapData;

  import Color;
  import Util;

  public class Map extends Entity {
    private var widthInTiles:int;
    private var heightInTiles:int;
    private var tileSize:int;
    private var tiles:Array = [];
    private var data:Array = [];
    private var topLeftCorner:Point = new Point(0, 0);

    function Map(widthInTiles:int, heightInTiles:int, tileSize:int) {
      super(0, 0, widthInTiles * tileSize, heightInTiles * tileSize)
      graphics.clear();

      this.widthInTiles = widthInTiles;
      this.heightInTiles = heightInTiles;
      this.tileSize = tileSize;

      var that:Map = this;

      tiles = Util.make2DArrayFn(widthInTiles, heightInTiles, function(x:int, y:int):Tile {
        var t:Tile = new Tile(x * tileSize, y * tileSize, tileSize, 0);
        that.addChild(t);
        return t;
      });

      addChild(tiles[0][0]);
    }

    public function fromImage(mapClass:Class):void {
      var bAsset:BitmapAsset = new mapClass();
      var bData:BitmapData = bAsset.bitmapData;

      data = Util.make2DArray(bData.width, bData.height, undefined);

      for (var x:int=0; x < bData.width; x++) {
        for (var y:int=0; y < bData.height; y++) {
          data[x][y] = (new Color()).readInt(bData.getPixel(x, y));
        }
      }

      updateTiles();
    }

    public function setTile(x:int, y:int, type:int):void {
      tiles[x][y].setType(type);
    }

    private function updateTiles():void {
      for (var x:int = 0; x < widthInTiles; x++) {
        for (var y:int = 0; y < heightInTiles; y++) {
          var val:int = 0;

          if (data[topLeftCorner.x + x][topLeftCorner.y + y].eq(new Color(0, 0, 0))) {
            val = 1;
          } else {
            val = 0;
          }

          setTile(x, y, val);
        }
      }
    }

    public override function collides(other:Entity):Boolean {
      if (this == other) return false;

      var xStart:int = Math.floor(other.x / this.tileSize);
      var yStart:int = Math.floor(other.y / this.tileSize);

      for (var x:int = xStart; x < xStart + 2; x++) {
        for (var y:int = yStart; y < yStart + 2; y++) {
          if (0 <= x && x < widthInTiles && 0 <= y && y < heightInTiles) {
            if (tiles[x][y].type == 1) {
              return true;
            }
          }
        }
      }

      return false;
    }

    public function moveCorner(diff:Vec):void {
      diff = diff.multiply(widthInTiles);

      topLeftCorner.x += diff.x;
      topLeftCorner.y += diff.y;

      updateTiles();
    }

    public override function groups():Array {
      return ["renderable", "wall", "map"];
    }
  }
}

class Tile extends flash.display.MovieClip {
  public var gfxWidth:int;
  public var gfxHeight:int;
  public var type:int;

  function Tile(x:int, y:int, w:int, type:int) {
    super();

    this.x = x;
    this.y = y;

    /* Great bug here. We can't call these width/height because
    width and height are determined by the contents of the MovieClip.
    Any attempt to set w/h here will see them implicitly returned to 0. */

    this.gfxWidth = w;
    this.gfxHeight = w;

    setType(type);
  }

  public function setType(type:int):void {
    var color:Color;

    this.type = type;

    if (type == 0) {
      color = (new Color()).randomizeRed(150, 255);
    } else {
      color = (new Color(255, 255, 0));
    }

    graphics.beginFill(color.toInt());
    graphics.drawRect(0, 0, this.gfxWidth, this.gfxHeight);
    graphics.endFill();
  }
}
