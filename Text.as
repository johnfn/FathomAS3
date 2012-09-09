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

    function Text(content:String = "", textName:String = null):void {
      this.content = content;

      var newFormat:TextFormat = new TextFormat();
      if (textName != null) newFormat.font = textName;
      newFormat.size = 16;

      textField = new TextField();
      textField.selectable = false;
      textField.wordWrap = true;
      textField.filters = [new DropShadowFilter(2.0, 45, 0, 1, 0, 0, 1)];
      textField.embedFonts = true;
      textField.defaultTextFormat = newFormat;
      textField.antiAliasType = "advanced";
      text = content;

      super(0, 0, 0, 0);

      addChild(textField);

      // You need to set the width after you add the TextField - otherwise, it'll
      // be reset to 0.
      textField.width = 200;
    }

    override public function set width(val:Number):void {
      textField.width = val;
    }

    public function set color(val:uint):void {
      textField.textColor = val;
    }

    public function get color():uint {
      return textField.textColor;
    }

    public function advanceOnKeypress(key:int):Text {
      listen(Hooks.keyRecentlyDown(key, advanceText));

      return this;
    }

    public function get text():String {
      return textField.text;
    }

    public function set text(s:String):void {
      textField.text = s;
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
      textField = null;
      content = null;
      typewriteTick = null;

      super.clearMemory();
    }
  }
}
