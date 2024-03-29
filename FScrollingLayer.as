package
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.display.Loader;
	import flash.net.URLRequest;

	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.utils.setTimeout;

	/**
	 * ...
	 * @author Zachary Foley
	 */

	 // Borrowed from http://plasticsturgeon.com/2010/06/infinite-scrolling-bitmap-backgrounds-in-as3/
	public class FScrollingLayer extends Sprite {
		protected var bitmapResource:Class;
		protected var scrollingBitmap:BitmapData;
		protected var _parallaxAmount:Number = 1;
		protected var graphPaperBmp:BitmapData;
		protected var canvas:Graphics;
		protected var matrix:Matrix;

		public function FScrollingLayer() {
			var loader:Loader = new Loader();
			loader.load(new URLRequest("file://Users/grantm/code/ld24/data/bg2.png"));
			addChild(loader);

			setTimeout(ef, 1000);
		}

		public function ef():void {
			var loader:Loader = new Loader();
			loader.load(new URLRequest("file://Users/grantm/code/ld24/data/bg2.png"));
			addChild(loader);

			setTimeout(ef, 1000);
		}

		/*
		protected function init(e:Event):void
		{
			matrix = this.transform.matrix.clone();
			removeEventListener(Event.ADDED_TO_STAGE, init);
			canvas = this.graphics;
			drawCanvas();
			stage.addEventListener(Event.RESIZE, handleResize);
		}

		protected function handleResize(e:Event):void
		{
			drawCanvas();
		}

		public function move(dx:Number, dy:Number):void {
			matrix.translate(dx, dy);
			drawCanvas();
		}

		public function get dy():Number { return matrix.ty; }

		public function set dy(value:Number):void
		{
			matrix.ty = value * _parallaxAmount;
			drawCanvas();
		}

		protected function drawCanvas():void
		{
			canvas.clear();
			canvas.beginBitmapFill(scrollingBitmap, matrix, true, true);
			canvas.drawRect(0,0,scrollingBitmap.width, scrollingBitmap.height);
		}

		public function get dx():Number { return matrix.tx; }

		public function set dx(value:Number):void
		{
			matrix.tx = value * _parallaxAmount;
			drawCanvas();
		}

		public function get parallaxAmount():Number { return _parallaxAmount; }

		public function set parallaxAmount(value:Number):void
		{
			_parallaxAmount = value;
		}
		*/

	}

}
