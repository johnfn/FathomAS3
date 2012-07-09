package {
  import flash.text.TextField;
  import flash.utils.setInterval;
  import flash.utils.clearInterval;

  import Hooks;
  import Util;
  import MagicArray;

  public class Text extends Entity implements IEqual {
    internal var textField:TextField;
    internal var content:String = "";

    function Text(x:Number = 0, y:Number = 0, content:String = ""):void {
      this.content = content;

      super(0, 0, 0, 0);
      mc.graphics.clear();

      textField = new TextField();
      textField.selectable = false;
      textField.x = x;
      textField.y = y;
      textField.text = content;

      Fathom.stage.addChild(textField);
    }

    public override function groups():Array {
      return super.groups().concat("updates-while-paused");
    }

    // Causes the classic videogame-ish effect of showing only 1 character
    // of text at a time.
    public function typewrite():Text {
      var fullContent:String = this.content;
      var counter:int = 0;
      var id:int = 0;

      textField.text = "";

      var typewriteTick:Function = function():void {
        if (counter > fullContent.length) {
          off("pre-update", typewriteTick);
        }

        textField.appendText(fullContent.charAt(counter));
        counter++;
      }

      on("pre-update", typewriteTick);

      return this;
    }
  }
}
