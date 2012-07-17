package {
  import flash.text.TextField;
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
      textField.selectable = false;
      textField.x = x;
      textField.y = y;

      text = content;

      Fathom.stage.addChild(textField);

      listen(Hooks.keyRecentlyDown(Util.Key.Z, advanceText));

      if (width == -1) {
        fixedWidth = false;
      } else {
        textField.width = width;
      }
    }

    public override function groups():Array {
      return super.groups().concat("updates-while-paused");
    }

    public function set text(s:String):void {
      textField.text = s;
      if (!fixedWidth) {
        textField.width = textField.textWidth;
      }
    }

    public function advanceText():void {
      if (typewriting) {
        stopTypewriting(this);
      } else {
        destroy();
      }
    }

    // Causes the classic videogame-ish effect of showing only 1 character
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
