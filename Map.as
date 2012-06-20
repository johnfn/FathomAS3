package {
	import flash.display.Sprite;
	import flash.geom.Point;
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

			widthInTiles = widthInTiles;
			heightInTiles = heightInTiles;
			tileSize = tileSize;

			tiles = Util.make2DArray(widthInTiles, heightInTiles, undefined);
		}

		public function fromImage(mapClass:Class) {
			var bAsset:BitmapAsset = new mapClass();
			var bData:BitmapData = bAsset.bitmapData;

      data = Util.make2DArray(bData.width, bData.height, undefined);

			for (var x:int=0; x < bData.width; x++) {
				for (var y:int=0; y < bData.height; y++) {
					data[x][y] = (new Color()).readInt(bData.getPixel(x, y))
				}
			}

      trace(data[0][0].toString());
		}

		public function setTile(x:int, y:int, type:int) {
			tiles[x][y] = new Tile(x * tileSize, y * tileSize, tileSize, type);
		}

		public function moveCorner(diff:Vec) {
			diff = diff.multiply(widthInTiles);

			topLeftCorner.x += diff.x;
			topLeftCorner.y += diff.y;

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

		public override function groups():Array {
			return ["renderable", "wall", "map"];
		}
	}
}

class Tile extends flash.display.Sprite {
  function Tile(x:int, y:int, width:int, type:int) {
    x=x;
    y=y;
    width=width;
    height=height;

    var color:Color;

    if (type == 0) {
      color = (new Color()).randomizeRed(150, 255);
    } else {
      color = (new Color(255, 255, 0));
    }

    graphics.beginFill(color.toInt());
    graphics.drawRect(x, y, width, height);
  }
}


