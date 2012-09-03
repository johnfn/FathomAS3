package {
  // This class mimics the Set data type found in languages like Python.

  public class Set {
    import flash.utils.Dictionary;

    private var contents:Dictionary = new Dictionary();
    private var _length:int = 0;

    public function Set(init:Array = null) {
        if (init == null) return;

        for (var i:int = 0; i < init.length; i++) {
            add(init[i]);
        }
    }

    public function add(item:*):void {
        if (!contents[item]) {
            _length++;
        }

        contents[item] = true;
    }

    public function remove(item:*):void {
        if (!contents[item]) {
            throw new Error("Set#remove called on non-existant item");
        }

        contents[item] = undefined;
        _length--;
    }

    // TODO: Eventually just override for-in

    public function foreach(f:Function):void {
        for (var k:* in contents) {
            f(k);
        }
    }

    public function has(item:*):Boolean {

        // This looks redundant, but if we don't have the item
        // contents[item] == undefined.

        return contents[item] == true;
    }

    public static function merge(s1:Set, s2:Set):Set {
        var result:Set = new Set();
        var k:*;

        for (k in s1.contents) {
            result.add(k);
        }

        for (k in s2.contents) {
            result.add(k);
        }

        return result;
    }

    public function extend(other:Set):void {
        for (var k:* in other.contents) {
            add(k);
        }
    }

    public function get length():int {
        return _length;
    }

    public function toArray():Array {
      var result:Array = [];

      for (var k:* in contents) {
        result.push(k);
      }

      return result;
    }

    public function any(f:Function):Boolean {
        for (var k:* in contents) {
            if (f(k)) {
                return true;
            }
        }

        return false;
    }

    public function toString():String {
        var result:String = "{ ";

        for (var k:* in contents) {
            result += k.toString() + ", ";
        }

        result += " }";

        return result;
    }
  }
}
