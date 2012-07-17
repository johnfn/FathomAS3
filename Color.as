package {
  import Util;

  public class Color {
    public var r:int;
    public var g:int;
    public var b:int;
    public var a:int;

    function Color(r:int = 0, g:int = 0, b:int = 0, a:int = 255) {
      this.r = r;
      this.g = g;
      this.b = b;
      this.a = a;
    }

    private function zeroPad(str:String, padLength:int=2):String {
      while (str.length < padLength) {
        str = "0" + str;
      }

      return str;
    }

    public function toString():String {
      return "#" + zeroPad(r.toString(16))
                 + zeroPad(g.toString(16))
                 + zeroPad(b.toString(16));
    }

    public function fromInt(hex:int):Color {
      r = ((hex & 0xFF0000) >> 16);
      g = ((hex & 0x00FF00) >> 8);
      b = ((hex & 0x0000FF));

      return this;
    }

    public function read(s:String):Color {
      s = s.substring(1);

      r = parseInt(s.substring(0, 2), 16);
      g = parseInt(s.substring(2, 4), 16);
      b = parseInt(s.substring(4, 6), 16);

      return this;
    }

    //TODO: implement IEqual
    public function eq(c:Color):Boolean {
      return r == c.r && g == c.g && b == c.b && a == c.a;
    }

    public function toInt():uint {
      return parseInt(toString().substring(1), 16);
    }

    public function randomizeRed(low:int = 0, high:int = 255):Color {
      r = Util.randRange(low, high);
      return this;
    }

    public function randomizeGreen(low:int = 0, high:int = 255):Color {
      g = Util.randRange(low, high);
      return this;
    }

    public function randomizeBlue(low:int = 0, high:int = 255):Color {
      b = Util.randRange(low, high);
      return this;
    }
  }
}
