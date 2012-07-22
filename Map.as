package {
  import flash.display.Sprite;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import mx.core.BitmapAsset;
  import flash.display.BitmapData;

  import Color;
  import Util;

  public class Map extends Rect {
    private var widthInTiles:int;
    private var heightInTiles:int;
    private var tileSize:int;
    private var data:Array = []; // Color data from the map.
    private var tiles:Array = []; // Cached array of collideable tiles.
    private var topLeftCorner:Vec = new Vec(0, 0);
    private var exploredMaps:Object = {};

    private var persistentItemMapping:Object = {};
    private var persistent:Object = {};

    public var sizeVector:Vec;

    function Map(widthInTiles:int, heightInTiles:int, tileSize:int) {
      super(0, 0, widthInTiles * tileSize, heightInTiles * tileSize);

      this.sizeVector = new Vec(width, height);
      this.widthInTiles = widthInTiles;
      this.heightInTiles = heightInTiles;
      this.tileSize = tileSize;

      this.clearTiles();
    }

    private function clearTiles():void {
      tiles = Util.make2DArrayFn(widthInTiles, heightInTiles, function(x:int, y:int):Tile {
        return null;
      });
    }

    //TODO: Should be a getter.
    public function getTileSize():int {
      return tileSize;
    }

    [Embed(source = "../data/map.png")] static public var MapClass:Class;

    public function fromImage(mapClass:Class, persistentItemMapping:Object):Map {
      var bAsset:BitmapAsset = new MapClass();
      var bData:BitmapData = bAsset.bitmapData;

      this.persistentItemMapping = persistentItemMapping;

      data = Util.make2DArray(bData.width, bData.height, undefined);

      for (var x:int=0; x < bData.width; x++) {
        for (var y:int=0; y < bData.height; y++) {
          data[x][y] = (new Color()).fromInt(bData.getPixel(x, y));
        }
      }

      updateTiles();

      return this;
    }

    private function switchMap(diff:Vec):void {
      // Hide old persistent items and get rid of permanently destroyed ones.
      var items:Array = persistent[topLeftCorner.asKey()];
      var processedItems:Array = [];
      var i:int;

      for (i = 0; i < items.length; i++) {
        if (!items[i].destroyed) {
          items[i].hide();
          processedItems.push(items[i]);
        }
      }

      persistent[topLeftCorner.asKey()] = processedItems;

      // Remove all impermanent items

      var impermanent:EntityList = Fathom.entities.get("!persistent");

      for (i = 0; i < impermanent.length; i++) {
        impermanent[i].destroy();
      }

      // Switch maps
      topLeftCorner.add(diff)

      if (!exploredMaps[topLeftCorner.asKey()]) return;

      // Add all persistent items that exist in this room.
      persistent[topLeftCorner.asKey()].map(function(e:*, i:int, a:Array):void {
        e.show();
      });
    }

    private function addPersistentItem(c:Color, x:int, y:int, seenBefore:Boolean):void {
      if (!(c.toString() in persistentItemMapping)) return;

      var itemData:Object = persistentItemMapping[c.toString()];
      var e:Entity = new itemData["type"]();

      if ("gfx" in itemData) {
        e.setExternalMC(itemData["gfx"], "fixedSize" in itemData);
      }

      e.set(new Vec(x * tileSize, y * tileSize));

      if (e.groups().contains("persistent")) {
        persistent[topLeftCorner.asKey()].push(e);
      }
    }

    private function updateTiles():void {
      var seenBefore:Boolean = exploredMaps[topLeftCorner.asKey()];

      this.clearTiles();

      if (!seenBefore) {
        persistent[topLeftCorner.asKey()] = [];

        for (var x:int = 0; x < widthInTiles; x++) {
          for (var y:int = 0; y < heightInTiles; y++) {
            var val:int = 0;
            var dataColor:Color = data[topLeftCorner.x + x][topLeftCorner.y + y];

            addPersistentItem(dataColor, x, y, seenBefore);
          }
        }
      }
      var persistingItems:Array = persistent[topLeftCorner.asKey()];

      for (var i:int = 0; i < persistingItems.length; i++) {
        var e:Entity = persistingItems[i];

        if (e.isStatic) {
          var xCoord = Math.floor(e.x / this.tileSize);
          var yCoord = Math.floor(e.y / this.tileSize);

          tiles[xCoord][yCoord] = e;
        }
      }

      exploredMaps[topLeftCorner.asKey()] = true;

      Fathom.sortDepths();
    }

    public function collidesPt(other:Point):Boolean {
      if (!containsPt(other)) return true;

      var xPt:int = Math.floor(other.x / this.tileSize);
      var yPt:int = Math.floor(other.y / this.tileSize);

      return tiles[xPt][yPt] != null;
    }

    public function collides(other:Entity):Boolean {
      var xStart:int = Math.floor(other.x / this.tileSize);
      var xStop:int  = Math.floor((other.x + other.width) / this.tileSize);
      var yStart:int = Math.floor(other.y / this.tileSize);
      var yStop:int  = Math.floor((other.y + other.height) / this.tileSize);

      for (var x:int = xStart; x < xStop + 1; x++) {
        for (var y:int = yStart; y < yStop + 1; y++) {
          if (0 <= x && x < widthInTiles && 0 <= y && y < heightInTiles) {
            if (tiles[x][y] != null) {
              return true;
            }
          }
        }
      }

      if (!makeBigger(3).containsRect(other)) return true;

      return false;
    }

    public override function toString():String {
      return "[Map]";
    }

    public function startingCorner(corner:Vec):Map {
      switchMap(corner.multiply(widthInTiles));
      updateTiles();

      return this;
    }

    public function moveCorner(diff:Vec):void {
      diff.divide(widthInTiles);

      switchMap(diff);

      updateTiles();
    }
  }
}
