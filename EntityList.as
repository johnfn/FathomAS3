package {
	import flash.debugger.enterDebugger;

  public class EntityList extends Set {
    function EntityList(entities:Array = null):void {
      super(entities);
    }

    public function get(...criteria):EntityList {

      var eList:EntityList = clone();

      for (var i:int = 0; i < criteria.length; i++) {
        eList = eList.myfilter(criteria[i]);
      }

      return eList;
    }

    public function clone():EntityList {
      return new EntityList(this.toArray());
    }

    public function union(...criteria):EntityList {
      var eList:EntityList = clone();
      var resultList:EntityList = new EntityList([]);

      for (var i:int = 0; i < criteria.length; i++) {
        var filteredList:EntityList = eList.myfilter(criteria[i]);

        for each (var e:Entity in filteredList) {
          resultList.add(e);
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

      for each (var e:Entity in results) {
        return e;
      }

      Util.assert(false); // It's impossible to ever get here. Ever.
      return null;
    }

    public function any(...criteria):Boolean {
      return this.get.apply(this, criteria).length > 0;
    }

    public function none(...criteria):Boolean {
      return this.get.apply(this, criteria).length == 0;
    }

    // Filters a list by 1 criteria item. Returns the filtered list.
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

      for each (var entity:Entity in this) {
        if (criteria is String) {
          if ((entity.groups().indexOf(criteria) != -1) == desired) {
            pass.push(entity);
          }

        } else if (criteria is Function) {
          if (criteria(entity)) {
            pass.push(entity);
          }
        } else {
          throw new Error("Unsupported Criteria type " + criteria + " " + Util.className(criteria));
        }
      }

      return new EntityList(pass);
    }
  }
}

