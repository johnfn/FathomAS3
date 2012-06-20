package {
	import flash.display.MovieClip;
	import flash.geom.Point;

	import Hooks;
	import Util;

	public class Entity extends MovieClip {
		private var __fathom:Object;

		function Entity(x:Number = 0, y:Number = 0, width:Number = 20, height:Number = -1, color:Number = 0xFF0000):void {
			if (height == -1) height = width;

			x = x;
			y = y;
			graphics.beginFill(color);
			graphics.drawRect(x, y, width, height);

			this.__fathom = { uid: Util.getUniqueID()
											, events: {}
										  , entities: Util.entities
										  };

			on("pre-update", Hooks.move(new Point(1, 0)));
			trace(this.__fathom.uid);
		}

		public function entities():Entities {
			return __fathom.entities;
		}

		public function on(event:String, callback:Function):Entity {
			var eventList = __fathom.events[event] || [];
			if (! (callback in eventList)) {
				eventList.push(callback);
			}

			__fathom.events[event] = eventList;

			return this;
		}

		public function off(event:String, callback:Function = null):Entity {
			var events = __fathom.events[event];
			if (!events) {
				throw "Don't have that event!";
			}

			if (callback) {
				__fathom.events[event] = events.splice(events.indexOf(callback), 1);
			} else {
				__fathom.events[event] = [];
			}

			return this;
		}

		public function emit(event:String):Entity {
			if (__fathom.events.indexOf(event) != -1) {
				for each (var hook:Function in __fathom.events[event]) {
					hook.call(this)
				}
			}

			return this;
		}

		public function die():void { __fathom.entities.remove(this); }

		public function groups():Array { return ["updateable"]; }

		public function eq(other):Boolean { return __fathom.uid == other.__fathom.uid; }

		public function collides(other):Boolean { return (!eq(other)) && hitTestObject(other); }

		public function update():void {}

		public function depth():Number { return 0; }


	}
}
