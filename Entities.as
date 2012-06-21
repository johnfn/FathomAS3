package {
  import flash.display.Sprite;
  public class Entities {
    public var entities:Array = [];

    public function add(entity:Entity):void {
      this.entities.push(entity);
    }

    public function get(...criteria):Array {
      var remainingEntities:Array = this.entities;

      for (var i:int = 0; i < criteria.length; i++){
        var item:* = criteria[i];
        var pass:Array = [];

        for (var i:int = 0; i < remainingEntities.length; i++){
          var entity:Entity = remainingEntities[i];

          if (item is String) {
            var desired:Boolean = true;
            if (item.charAt(0) == "!") {
              desired = false;
              item = item.substring(1);
            }

            if ((entity.groups().indexOf(item) != -1) == desired) {
              pass.push(entity);
            }

          } else if (item is Function) {
            if (item(entity)) {
              pass.push(entity);
            }
          } else {
            throw new Error("Unsupported Criteria type.");
          }
        }

        remainingEntities = pass;
      }

      return remainingEntities;
    }

    public function one(...criteria):Entity {
      var results:Array = this.get.apply(this, criteria);
      //assert(results.length == 1);
      return results[0];
    }

    public function any(...criteria):Boolean {
      return this.get.apply(this, criteria).length > 0;
    }

    public function update():void {
      var updaters:Array = this.get("updateable");

      for (var i:int = 0; i < updaters.length; i++) {
        var e:Entity = updaters[i];
        e.emit("pre-update");
        e.update(this);
        e.emit("post-update");
      }
    }
  }
}
