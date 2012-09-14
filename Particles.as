package {

	import flash.display.Sprite;
	import mx.core.BitmapAsset;
	import flash.utils.Dictionary;

	public class Particles {
		private static var particleEffects:Array = [];

		private var deadParticles:Array = [];

		// Number from 0 to 1 - % chance of spawning the particle on a single frame.
		private var spawnRate:Number = 0.5;

		private var lifetimeLow:int = 60;
		private var lifetimeHigh:int = 90;

		private var spawnLoc:Rect = new Rect(0, 0, 500, 500);

		private var velXLow:int = -2;
		private var velXHigh:int = 2;

		private var velYLow:int = -2;
		private var velYHigh:int = 2;

		private var stopParticleGen:int = -1;

		private var particleData:Dictionary = new Dictionary();

		private var baseMC:Class;

		public function Particles(baseMC:Class):void {
			this.baseMC = baseMC;

			particleEffects.push(this);
		}

		// Chainable methods for ease of constructing particle effects.

		public function withLifetime(newLow:int, newHigh:int):Particles {
			this.lifetimeLow = newLow;
			this.lifetimeHigh = newHigh;

			return this;
		}

		public function withVelX(newXLow:int, newXHigh:int):Particles {
			this.velXLow  = newXLow;
			this.velXHigh = newXHigh;

			return this;
		}

		public function withVelY(newYLow:int, newYHigh:int):Particles {
			this.velYLow  = newYLow;
			this.velYHigh = newYHigh;

			return this;
		}

		// This terminates the entire Particle generator, not individual particles.
		// Time is in frames.
		public function thatStopsAfter(time:int):Particles {
			stopParticleGen = time;

			return this;
		}

		private function killParticle(p:Sprite):void {
			delete particleData[p];
		}

		public static function removeParticleEffect(p:Particles):void {
			Particles.particleEffects.remove(p);
		}

		public static function updateAll():void {
			for (var i:int = 0; i < Particles.particleEffects.length; i++) {
				Particles.particleEffects[i].update();
			}
		}

		public function update():void {
			stopParticleGen--;

			if (stopParticleGen == 0) {
				Particles.removeParticleEffect(this);
				return;
			}

			// See if we should make a new particle.
			if (Math.random() < spawnRate) {
				var newParticle:Sprite;
				var newData:Object = {};

				if (deadParticles.length > 0) {
					newParticle = deadParticles.pop();
				} else {
					var bAsset:BitmapAsset = new baseMC();
					newParticle = new Sprite();
					newParticle.addChild(bAsset);
				}

				newData.life = Util.randRange(lifetimeLow, lifetimeHigh);
				newData.vel = new Vec(Util.randRange(velXLow, velXHigh),
					                       Util.randRange(velYLow, velYHigh));

				newData.x = Util.randRange(spawnLoc.x, spawnLoc.right);
				newData.y = Util.randRange(spawnLoc.y, spawnLoc.bottom);

				particleData[newParticle] = newData;

				Fathom.container.addChild(newParticle);
			}

			// Update each particle.
			for (var pObj:* in particleData) {
				var p:Sprite = pObj as Sprite;
				var data:Object = particleData[p];

				data.x += data.vel.x;
				data.y += data.vel.y;

				pObj.x = data.x;
				pObj.y = data.y;

				// Since we're (currently) not using Entities, we need to
				// manually translate to camera space.

				Fathom.camera.translateSingleObject(p);

				// Kill the particle, if necessary.
				if (data["life"]-- == 0) {
					delete particleData[p];
					deadParticles.push(p);
				}
			}
		}
	}
}