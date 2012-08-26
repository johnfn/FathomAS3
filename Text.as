package {
  import flash.filters.DropShadowFilter;
  import flash.text.TextField;
  import flash.text.TextFormat;
  import flash.utils.setInterval;
  import flash.utils.clearInterval;

  import Hooks;
  import Util;
  import MagicArray;

  public class Text extends Entity {
    internal var textField:TextField;
    internal var content:String = "";

    private var typewriting:Boolean = false;
    private var typewriteTick:Function;
    private var fixedWidth:Boolean = false;

    function Text(x:Number = 0, y:Number = 0, content:String = "", width:int = -1):void {
      this.content = content;

      super(0, 0, 0, 0);
      mc.graphics.clear();

      textField = new TextField();
      text = content;

      textField.selectable = false;
      textField.x = x;
      textField.y = y;
      textField.wordWrap = true;

      textField.filters = [new DropShadowFilter(1.0, 45, 0, 1, 0, 0, 1)];

      mc.addChild(textField);

      if (width == -1) {
        fixedWidth = false;
      } else {
        textField.width = width;
        textField.height = 200;
        fixedWidth = true;
      }
    }

    //TODO entities have color?
    public function set textColor(val:uint):void {
      textField.textColor = val;
    }

    public function advanceOnKeypress(key:int):Text {
      listen(Hooks.keyRecentlyDown(key, advanceText));

      return this;
    }

    public override function groups():Array {
      return super.groups().concat("updates-while-paused");
    }

    public function set text(s:String):void {
      textField.text = s;
      if (!fixedWidth) {
        textField.width = textField.textWidth;
      }

      var newFormat:TextFormat = new TextFormat();
      newFormat.size = 14;
      newFormat.font = "Arial";
      textField.setTextFormat(newFormat);
    }

    public function advanceText():void {
      if (typewriting) {
        stopTypewriting(this);
      } else {
        destroy();
      }
    }

    // The classic videogame-ish effect of showing only 1 character
    // of text at a time.
    public function typewrite():Text {
      var counter:int = 0;
      var id:int = 0;
      var that:Text = this;

      typewriting = true;
      textField.text = "";

      this.typewriteTick = function():void {
        if (counter > that.content.length) {
          stopTypewriting(that);
          return;
        }

        textField.appendText(that.content.charAt(counter));
        counter++;
      }

      on("pre-update", this.typewriteTick);

      return this;
    }

    public function stopTypewriting(t:Text):void {
      textField.text = content;
      typewriting = false;
      off("pre-update", this.typewriteTick);
    }

    public override function clearMemory():void {
      textField.parent.removeChild(textField);
      textField = null;
      content = null;

      super.clearMemory();
    }
  }
}
