package {
  //TODO: extends Vector.<Entity>

  public dynamic class EntityList extends Array {
    function EntityList(entities:Array):void {
      if (entities is Array) {
        for (var i:int = 0; i < entities.length; i++) {
          this[i] = entities[i];
        }
      }
    }

    public function first():Entity {
      return this[0];
    }

    //TODO: A bit weird that this is the only non mutable fn.
    public function add(entity:Entity):void {
      this.push(entity);
    }

    public function get(...criteria):EntityList {
      var eList:EntityList = new EntityList(this);

      for (var i:int = 0; i < criteria.length; i++) {
        eList = eList.myfilter(criteria[i]);
      }

      return eList;
    }

    public function one(...criteria):Entity {
      var results:EntityList = this.get.apply(this, criteria);
      Util.assert(results.length == 1);

      return results.first();
    }

    public function any(...criteria):Boolean {
      return this.get.apply(this, criteria).length > 0;
    }

    public function none(...criteria):Boolean {
      return this.get.apply(this, criteria).length == 0;
    }

    public function update():void {
      var updaters:EntityList = this.get("updateable");

      for (var i:int = 0; i < updaters.length; i++) {
        var e:Entity = updaters[i];

        // There is a possibility that an earlier update() caused this entity
        // to destroy itself. If so, skip it.
        if (e.destroyed) continue;

        e.emit("pre-update");
        e.update(this);
        e.emit("post-update");
      }
    }

    public function exclude(criteria:IEqual):EntityList {
      var pass:Array = [];

      for (var i:int = 0; i < this.length; i++) {
        if (! criteria.equals(this[i])) {
          pass.push(this[i]);
        }
      }

      return new EntityList(pass);
    }

    public function myfilter(criteria:*):EntityList {
      var pass:Array = [];

      for (var i:int = 0; i < this.length; i++){
        var entity:Entity = this[i];

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
