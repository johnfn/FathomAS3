package {
  //TODO: extends Array (or Vector.<Entity>)

  public class EntityList {
    private var entities:Array = [];

    function EntityList(entities:Array):void {
      this.entities = entities;
    }

    public function first():Entity {
      return entities[0];
    }

    public function length():int {
      return entities.length;
    }

    public function at(n:int):Entity {
      return entities[n];
    }

    //TODO: A bit weird that this is the only non mutable fn.
    public function add(entity:Entity):void {
      this.entities.push(entity);
    }

    public function get(...criteria):EntityList {
      var eList:EntityList = new EntityList(this.entities);

      for (var i:int = 0; i < criteria.length; i++) {
        eList = eList.filter(criteria[i]);
      }

      return eList;
    }

    public function one(...criteria):Entity {
      //assert(results.length == 1);
      return this.get.apply(this, criteria).first();
    }

    public function any(...criteria):Boolean {
      return this.get.apply(this, criteria).length() > 0;
    }

    public function update():void {
      var updaters:EntityList = this.get("updateable");

      for (var i:int = 0; i < updaters.length(); i++) {
        var e:Entity = updaters.at(i);
        e.emit("pre-update");
        e.update(this);
        e.emit("post-update");
      }
    }

    public function exclude(criteria:*):EntityList {
      var pass:Array = [];

      for (var i:int = 0; i < entities.length; i++) {
        if (criteria.__fathom.uid != entities[i].__fathom.uid) {
          pass.push(entities[i]);
        }
      }

      return new EntityList(pass);
    }

    public function toString():String {
      return this.entities.toString();
    }

    public function filter(criteria:*):EntityList {
      var pass:Array = [];

      for (var i:int = 0; i < entities.length; i++){
        var entity:Entity = entities[i];

        if (criteria is String) {
          var desired:Boolean = true;
          if (criteria.charAt(0) == "!") {
            desired = false;
            criteria = criteria.substring(1);
          }

          if ((entity.groups().indexOf(criteria) != -1) == desired) {
            pass.push(entity);
          }

        } else if (criteria is Function) {
          if (criteria(entity)) {
            pass.push(entity);
          }
        } else {
          throw new Error("Unsupported Criteria type.");
        }
      }

      return new EntityList(pass);
    }
  }
}
