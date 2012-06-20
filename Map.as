package {
	import flash.display.Sprite;
	import flash.geom.Point;
	import Util;

	private var widthInTiles:int;
	private var heightInTiles:int;
	private var tileSize:int;
	private var tiles:Array = [];
	private var data:Array = [];
	private var topLeftCorner:Point = new Point(0, 0);

	class Tile extends Rectangle {
		function Tile(x, y, width, type) {
			super(x, y, width, width);

			if (type == 0) {
				color = (new Color()).randomizeRed(150, 255).toString();
			} else {
				color = (new Color(255, 255, 0)).toString();
			}


			graphics.beginFill(color);
			graphics.drawRect(x, y, width, height);
		}
	}

	public class Map extends Entity {
		function Map(widthInTiles, heightInTiles, tileSize) {
			widthInTiles = widthInTiles;
			heightInTiles = heightInTiles;
			tileSize = tileSize;

			tiles = Util.make2DArray(widthInTiles, heightInTiles, undefined);
		}

		public function setTile(x:int, y:int, type:int) {
			tiles[x][y] = new Tile(x * tileSize, y * tileSize, tileSize, type);
		}

		public function moveCorner(diff
	}
}
