package {
  public class Tile extends Entity {
    private var type:int;
    private const SIZE:int = C.size;

    function Tile(x:int=0, y:int=0, type:int=0) {
      super(x, y, SIZE, SIZE, true);
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

    public function setType(type:int):Tile {
      this.color = typeToColor(type).toInt();
      this.draw();

      return this;
    }
  }
}
