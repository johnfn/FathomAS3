package {
	import flash.debugger.enterDebugger;

  //TODO: extends Vector.<Entity>

  public dynamic class EntityList extends Array {
    function EntityList(entities:Array):void {
      if (entities is Array) {
        for (var i:int = 0; i < entities.length; i++) {
          this[i] = entities[i];
        }
      }
    }

    public function each(f:Function):void {
      for (var i:int = 0; i < length; i++) {
        f(this[i]);
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
      var eList:EntityList = clone();

      for (var i:int = 0; i < criteria.length; i++) {
        eList = eList.myfilter(criteria[i]);
      }

      return eList;
    }

    public function clone():EntityList {
      return new EntityList(this);
    }

    public function union(...criteria):EntityList {
      var eList:EntityList = clone();
      var resultList:EntityList = new EntityList([]);

      for (var i:int = 0; i < criteria.length; i++) {
        var filteredList:EntityList = eList.myfilter(criteria[i]);

        for (var j:int = 0; j < filteredList.length; j++) {
          if (!resultList.contains(filteredList[j])) {
            resultList.push(filteredList[j]);
          }
        }
      }

      return resultList;
    }

    public function one(...criteria):Entity {
      var results:EntityList = this.get.apply(this, criteria);

      if (results.length == 0) {
        throw new Error("EntityList#one called with criteria "+ criteria.toString()+ ", but no results found.");
      } else if (results.length > 1) {
        throw new Error("EntityList#one called with criteria "+ criteria.toString()+ ", and "+ results.length+ " results found.");
      }

      return results.first();
    }

    public function any(...criteria):Boolean {
      return this.get.apply(this, criteria).length > 0;
    }

    public function none(...criteria):Boolean {
      return this.get.apply(this, criteria).length == 0;
    }

    // Filters a list by 1 criteria item. Does not mutate the list.
    //
    // Criteria types:
    //
    // * String   -> match all entities with that group
    //
    // * !String  -> in the case that the string starts with "!",
    //              perform the inverse of the above.
    //
    // * Function -> match all entities e such that f(e) == true.

    public function myfilter(criteria:*):EntityList {
      var pass:Array = [];
      var desired:Boolean = true;

      if (criteria is String && criteria.charAt(0) == "!") {
        desired = false;
        criteria = criteria.substring(1);
      }

      for (var i:int = 0; i < this.length; i++){
        var entity:Entity = this[i];

        if (criteria is String) {
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

