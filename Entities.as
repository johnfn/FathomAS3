package {
	import flash.display.Sprite;
	public class Entities {
		public var entities:Array = [];

		public function main():void {
			this.entities = [];
		}

		public function add(entity):void {
			this.entities.push(entity);
		}

		public function get(...criteria):Array {
			var remainingEntities = this.entities;

			for each (var item in criteria) {
				var pass = [];

				for each (var entity in remainingEntities){
					if (item is String) {
						var desired = true;
						if (item[0] == "!") {
							desired = false;
							item = item.substring(1);
						}

						if (item in entity.groups() == desired) {
							pass.push(entity);
						}
					}

					if (item is Function) {
						if (item(entity)) {
							pass.push(entity);
						}
					}

					throw new Error("Unsupported Criteria type.");
				}

				remainingEntities = pass;
			}

			return remainingEntities;
		}

		public function one(...criteria):Entity {
			var results = this.get.apply(this, criteria);
			//assert(results.length == 1);
			return results[0];
		}

		public function any(...criteria):Boolean {
			return this.get.apply(this, criteria).length > 0;
		}

		public function update():void {
			for each (var e in this.get("updateable")) {
				e.emit("pre-update");
				e.update(this);
				e.emit("post-update");
			}
		}
	}
}
