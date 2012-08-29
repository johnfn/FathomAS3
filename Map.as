package {
  import flash.display.Sprite;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import mx.core.BitmapAsset;
  import flash.display.BitmapData;

  import Color;
  import Util;
  import Entity;

  //TODO: Map should extend Entity. Will need to change update loop.

  public class Map extends Rect {
    private var widthInTiles:int;
    private var heightInTiles:int;

    private var _tileSize:int;
    private var data:Array = []; // Color data from the map.
    private var tiles:Array = []; // Cached array of collideable tiles.
    private var topLeftCorner:Vec = new Vec(0, 0);
    private var exploredMaps:Object = {};

    private var persistentItemMapping:Object = {};
    private var persistent:Object = {};

    public var sizeVector:Vec;

    function Map(widthInTiles:int, heightInTiles:int, tileSize:int) {
      super(0, 0, widthInTiles * tileSize, heightInTiles * tileSize);

      Util.assert(widthInTiles == heightInTiles);

      this.sizeVector = new Vec(width, height);
      this.widthInTiles = widthInTiles;
      this.heightInTiles = heightInTiles;
      this._tileSize = tileSize;

      this.clearTiles();

      // Initialize the persistent object

      for (var i:int = 0; i < 1000; i += widthInTiles) {
        for (var j:int = 0; j < 1000; j += heightInTiles) {
          persistent[new Vec(i, j).asKey()] = [];
        }
      }

    }

    private function clearTiles():void {
      tiles = Util.make2DArrayFn(widthInTiles, heightInTiles, function(x:int, y:int):Tile {
        return null;
      });
    }

    public function get tileSize():int {
      return _tileSize;
    }

    public function fromImage(mapClass:Class, persistentItemMapping:Object):Map {
      var bAsset:BitmapAsset = new mapClass();
      var bData:BitmapData = bAsset.bitmapData;

      this.persistentItemMapping = persistentItemMapping;

      data = Util.make2DArray(bData.width, bData.height, undefined);

      for (var x:int=0; x < bData.width; x++) {
        for (var y:int=0; y < bData.height; y++) {
          data[x][y] = Color.fromInt(bData.getPixel(x, y));
        }
      }

      return this;
    }

    private function hideCurrentPersistentItems():void {
      var processedItems:Array = [];
      var items:Array = persistent[topLeftCorner.asKey()];

      for (var i:int = 0; i < items.length; i++) {
        if (!items[i].destroyed) {
          items[i].removeFromFathom();
          processedItems.push(items[i]);
        }
      }

      persistent[topLeftCorner.asKey()] = processedItems;
    }

    private function updatePersistentItems(diff:Vec):void {
      hideCurrentPersistentItems();

      Fathom.entities.get("!persistent").each(function(e:Entity):void {
        e.destroy();
      });

      topLeftCorner.add(diff)

      addNewPersistentItems();
    }

    private function addPersistentItem(c:Color, x:int, y:int):void {
      if (!(c.toString() in persistentItemMapping)) {
        if (c.toString() != "#ffffff") {
          trace("Color without data: " + c.toString());
        }
        return;
      }

      var itemData:Object = persistentItemMapping[c.toString()];
      var e:Entity = new itemData["type"]();

      if ("gfx" in itemData) {
        if ("spritesheet" in itemData) {
          // This is an awesome feature that I need to explain more when I'm not doing Ludum Dare. TODO
          if ("roundOutEdges" in itemData) {
            var result:Array = itemData["spritesheet"].slice();
            var X:int = 0;
            var Y:int = 1;

            var locX:int = topLeftCorner.x + x;
            var locY:int = topLeftCorner.y + y;

            if (locY == 0 || data[locX][locY - 1].toString() != c.toString()) {
              result[Y]--;
            }

            if (locX == 0 || data[locX - 1][locY].toString() != c.toString()) {
              result[X]--;
            }

            if (locY != heightInTiles - 1 && data[locX][locY + 1].toString() != c.toString()) {
              result[Y]++;
            }

            if (locX == widthInTiles - 1 || data[locX + 1][locY].toString() != c.toString()) {
              result[X]++;
            }

            if (locY != 0 && data[locX][locY - 1].toString() != c.toString()  && locY != heightInTiles - 1 && data[locX][locY + 1].toString() != c.toString()) {
              result[Y]--;
            }

            e.fromExternalMC(itemData["gfx"], "fixedSize" in itemData, result);

          } else {
            e.fromExternalMC(itemData["gfx"], "fixedSize" in itemData, itemData["spritesheet"]);
          }
        } else {
          e.fromExternalMC(itemData["gfx"], "fixedSize" in itemData);
        }
      }

      e.setPos(new Vec(x * tileSize, y * tileSize));

      if (e.groups().contains("persistent")) {
        persistent[topLeftCorner.asKey()].push(e);
      }

      if (e.groups().contains("remember-loc")) {
        (e as PushBlock).rememberLoc();
      }
    }

    private function addNewPersistentItems():void {
      var seenBefore:Boolean = exploredMaps[topLeftCorner.asKey()];

      this.clearTiles();

      // Scan the map, adding every object to our list of persistent items for this map.
      if (!seenBefore) {
        // If we haven't seen it before, load in all the persistent items.

        for (var x:int = 0; x < widthInTiles; x++) {
          for (var y:int = 0; y < heightInTiles; y++) {
            var dataColor:Color = data[topLeftCorner.x + x][topLeftCorner.y + y];

            addPersistentItem(dataColor, x, y);
          }
        }
      } else {

        // Add all persistent items.
        persistent[topLeftCorner.asKey()].map(function(e:*, i:int, a:Array):void {
          e.addToFathom();

          if (e.groups().contains("remember-loc")) {
            e.resetLoc();
          }
        });
      }

      // Cache every persistent item in the 2D array of tiles.
      var persistingItems:Array = persistent[topLeftCorner.asKey()];

      for (var i:int = 0; i < persistingItems.length; i++) {
        var e:Entity = persistingItems[i];

        if (e.isStatic) {
          var xCoord:int = Math.floor(e.x / this.tileSize);
          var yCoord:int = Math.floor(e.y / this.tileSize);

          tiles[xCoord][yCoord] = e;
        }
      }

      exploredMaps[topLeftCorner.asKey()] = true;
    }

    public function itemSwitchedMaps(leftScreen:Entity):void {
      var smallerSize:Vec = sizeVector.clone().subtract(leftScreen.width);
      var dir:Vec = leftScreen.rect().divide(smallerSize).map(Math.floor);
      var newMapLoc:Vec = topLeftCorner.clone().add(dir.clone().multiply(widthInTiles));
      var newItemLoc:Vec = leftScreen.rect().add(dir.clone().multiply(-1).multiply(sizeVector.clone().subtract(tileSize * 2)));

      persistent[topLeftCorner.asKey()].remove(leftScreen);
      if (!persistent[newMapLoc.asKey()]) {
        persistent[newMapLoc.asKey()] = [];
      }
      persistent[newMapLoc.asKey()].push(leftScreen);

      leftScreen.setPos(newItemLoc);

      leftScreen.removeFromFathom();
    }

    private function collidesPt(other:Vec):Boolean {
      if (!contains(other)) return true;

      var xPt:int = Math.floor(other.x / this.tileSize);
      var yPt:int = Math.floor(other.y / this.tileSize);

      return tiles[xPt][yPt] != null;
    }

    private function collidesRect(other:Rect):Boolean {
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

      if (!makeBigger(3).contains(other)) return true;

      return false;
    }

    public function collides(i:*):Boolean {
      if (i is Vec) {
        return collidesPt(i as Vec);
      }

      if (i is Rect) {
        return collidesRect(i as Rect);
      }

      throw new Error("Unsupported type for Map#collides.")
    }

    public function update():void {
      var items:Array = persistent[topLeftCorner.asKey()];

      for (var i:int = 0; i < items.length; i++) {
        if (Hooks.hasLeftMap(items[i], this)) {
          Util.assert(items[i].groups().indexOf("Character") == -1);
          this.itemSwitchedMaps(items[i]);
        }
      }
    }

    public override function toString():String {
      return "[Map]";
    }

    public function startingCorner(corner:Vec):Map {
      topLeftCorner = corner.multiply(widthInTiles);

      return this;
    }

    public function modes():Array {
      return [0];
    }

    public function loadNewMap(diff:Vec):void {
      diff.multiply(new Vec(widthInTiles, heightInTiles));

      updatePersistentItems(diff);
      Fathom.container.sortDepths();
    }

    public function getTopLeftCorner():Vec {
      return this.topLeftCorner;
    }
  }
}
