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
    private var tiles:Array = [];
    private var data:Array = [];
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

      tiles = Util.make2DArrayFn(widthInTiles, heightInTiles, function(x:int, y:int):Tile {
        return new Tile(x * tileSize, y * tileSize, tileSize, 0);
      });
    }

    //TODO: Should be a getter.
    public function getTileSize():int {
      return tileSize;
    }

    public function fromImage(mapClass:Class, persistentItemMapping:Object):Map {
      var bAsset:BitmapAsset = new mapClass();
      var bData:BitmapData = bAsset.bitmapData;

      this.persistentItemMapping = persistentItemMapping;

      data = Util.make2DArray(bData.width, bData.height, undefined);

      for (var x:int=0; x < bData.width; x++) {
        for (var y:int=0; y < bData.height; y++) {
          data[x][y] = (new Color()).readInt(bData.getPixel(x, y));
        }
      }

      updateTiles();

      return this;
    }

    public function setTile(x:int, y:int, type:int):void {
      tiles[x][y].setType(type);
    }

    public function addPersistentItem(item:Entity):void {
      persistent[topLeftCorner.asKey()].push(item);
    }

    private function addPersistentItems(c:Color, x:int, y:int):Color {
      if (!(c.toString() in persistentItemMapping)) return c;
      var e:Entity = (new persistentItemMapping[c.toString()]).set(new Vec(x, y));

      if (e.groups().contains("persistent")) addPersistentItem(e);

      return new Color(255, 255, 255);
    }

    private function switchMap(diff:Vec):void {
      // TODO: enemies should be persistent.
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

    private function updateTiles():void {
      var seenBefore:Boolean = exploredMaps[topLeftCorner.asKey()];

      if (!seenBefore) {
        persistent[topLeftCorner.asKey()] = [];
      }

      for (var x:int = 0; x < widthInTiles; x++) {
        for (var y:int = 0; y < heightInTiles; y++) {
          var val:int = 0;
          var dataColor:Color = data[topLeftCorner.x + x][topLeftCorner.y + y];

          if (!seenBefore) {
            dataColor = addPersistentItems(dataColor, x * tileSize, y * tileSize);
          }

          if (dataColor.eq(new Color(0, 0, 0))) {
            val = 1;
          } else {
            val = 0;
          }

          setTile(x, y, val);
        }
      }

      exploredMaps[topLeftCorner.asKey()] = true;
    }

    public function collidesPt(other:Point):Boolean {
      if (!containsPt(other)) return true;

      var xPt:int = Math.floor(other.x / this.tileSize);
      var yPt:int = Math.floor(other.y / this.tileSize);

      return tiles[xPt][yPt].type == 1;
    }

    public function collides(other:Entity):Boolean {
      var xStart:int = Math.floor(other.x / this.tileSize);
      var xStop:int  = Math.floor((other.x + other.width) / this.tileSize);
      var yStart:int = Math.floor(other.y / this.tileSize);
      var yStop:int  = Math.floor((other.y + other.height) / this.tileSize);

      for (var x:int = xStart; x < xStop + 1; x++) {
        for (var y:int = yStart; y < yStop + 1; y++) {
          if (0 <= x && x < widthInTiles && 0 <= y && y < heightInTiles) {
            if (tiles[x][y].type == 1) {
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

    public function moveCorner(diff:Vec):void {
      diff.divide(widthInTiles);

      switchMap(diff);

      updateTiles();
    }
  }
}

class Tile extends Entity {
  private var type:int;

  function Tile(x:int, y:int, w:int, type:int) {
    super(x, y, 20, 20, typeToColor(type).toInt());
  }

  private function typeToColor(type:int):Color {
    var color:Color;

    this.type = type;

    // TODO: This logic should not be here, at all.
    if (type == 0) {
      color = (new Color()).randomizeRed(150, 255);
    } else {
      color = (new Color(255, 255, 0));
    }

    return color;
  }

  public function setType(type:int):void {
    this.color = typeToColor(type).toInt();
    this.draw();
  }

  public override function collides(e:Entity):Boolean {
    if (this.type == 0) return false;

    return super.collides(e);
  }

  public override function groups():Array {
    return super.groups().concat("persistent");
  }
}
